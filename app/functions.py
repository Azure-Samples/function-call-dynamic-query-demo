import os
import json
import pyodbc
import struct
import logging
import threading
from decimal import Decimal
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv
import sqlparse
from sqlparse.tokens import Keyword, DML

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Define the connection string
connection_string = os.getenv("AZURE_SQL_CONNECTIONSTRING")

# Timeout in seconds
QUERY_TIMEOUT = 10

# Function to handle query timeout
def handler(signum, frame):
    raise TimeoutError(
        "This query took longer than the allotted time. Either the database server is experiencing performance issues or the generated query is too expensive. Please inspect the query or retry."
    )


# Function to get a database connection
def get_conn():
    try:
        credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
        token_bytes = credential.get_token("https://database.windows.net/.default").token.encode(
            "UTF-16-LE"
        )
        token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
        SQL_COPT_SS_ACCESS_TOKEN = (
            1256  # This connection option is defined by Microsoft in msodbcsql.h
        )

        conn = pyodbc.connect(
            connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct}
        )
        logger.info("Database connection established.")
        return conn
    except Exception as e:
        logger.error(f"Error establishing database connection: {e}")
        raise


# Function to convert decimal.Decimal to float
def convert_decimal(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError


# Function to check if the SQL query is read-only
def is_read_only_query(query):
    parsed = sqlparse.parse(query)
    for statement in parsed:
        for token in statement.tokens:
            if token.ttype is DML and token.value.upper() not in ["SELECT"]:
                return False
    return True


# Function to execute a SQL query with a timeout
def execute_query_with_timeout(query, timeout):
    if not is_read_only_query(query):
        logger.error(f"Disallowed write operation attempted: {query}")
        return json.dumps({"error": "Write operations are not allowed."})

    def query_execution(query, results):
        try:
            logger.info(f"Executing query: {query}")  # Log the generated query
            with get_conn() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(query)
                    columns = [column[0] for column in cursor.description]
                    rows = cursor.fetchall()
                    results.append([dict(zip(columns, row)) for row in rows])
        except Exception as e:
            results.append({"error": str(e)})

    results = []
    query_thread = threading.Thread(target=query_execution, args=(query, results))
    query_thread.start()
    query_thread.join(timeout)

    if query_thread.is_alive():
        logger.error("Query execution exceeded timeout limit.")
        return json.dumps(
            {
                "error": "This query took longer than the allotted time. Either the database server is experiencing performance issues or the generated query is too expensive. Please inspect the query or retry."
            }
        )
    else:
        return (
            json.dumps(results[0], default=convert_decimal)
            if results
            else json.dumps({"error": "No results returned."})
        )


# Function to execute a SQL query
def execute_query(query):
    return execute_query_with_timeout(query, QUERY_TIMEOUT)
