import os
import json
from azure.identity import DefaultAzureCredential
import pyodbc
import struct
from decimal import Decimal
import logging
from dotenv import load_dotenv

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Define the connection string
connection_string = os.getenv('AZURE_SQL_CONNECTIONSTRING')

# Function to get a database connection
def get_conn():
    try:
        credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
        token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")
        token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
        SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by Microsoft in msodbcsql.h
        
        logger.info("Attempting to establish a database connection...")
        conn = pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})
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

# Function to execute a SQL query
def execute_query(query):
    try:
        logger.info(f"Executing query: {query}")  # Log the generated query
        with get_conn() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query)
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                results = [dict(zip(columns, row)) for row in rows]
        return json.dumps(results, default=convert_decimal)
    except Exception as e:
        logger.error(f"Error executing query: {e}")
        return json.dumps({"error": str(e)})



get_conn()