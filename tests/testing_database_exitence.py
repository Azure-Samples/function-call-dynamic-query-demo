import pyodbc
from azure.identity import DefaultAzureCredential
import struct
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Define the connection string
connection_string = os.getenv('AZURE_SQL_CONNECTIONSTRING')

# Function to get a database connection
def get_conn():
    credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
    token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")
    token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
    SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by Microsoft in msodbcsql.h
    conn = pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})
    return conn

# Function to execute a SQL query
def execute_query(query):
    try:
        with get_conn() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query)
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                results = [dict(zip(columns, row)) for row in rows]
        return results
    except Exception as e:
        return {"error": str(e)}

# Test query
query = "SELECT TOP 1 * FROM SalesLT.Product"

# Execute the test query
result = execute_query(query)
print(result)
