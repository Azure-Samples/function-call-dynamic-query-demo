import os
import json
from azure.identity import DefaultAzureCredential
import pyodbc
import struct
from openai import AzureOpenAI
from dotenv import load_dotenv
from decimal import Decimal

# Load environment variables
load_dotenv()

# Define the Azure OpenAI client
client = AzureOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_version="2024-03-01-preview",
)

# Define the connection string
connection_string = os.getenv("AZURE_SQL_CONNECTIONSTRING")


# Function to get a database connection
def get_conn():
    credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
    token_bytes = credential.get_token("https://database.windows.net/.default").token.encode(
        "UTF-16-LE"
    )
    token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
    SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by Microsoft in msodbcsql.h
    conn = pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})
    return conn


# Function to convert decimal.Decimal to float
def convert_decimal(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError


# Function to execute a SQL query
def execute_query(query):
    try:
        with get_conn() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query)
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                results = [dict(zip(columns, row)) for row in rows]
        return json.dumps(results, default=convert_decimal)
    except Exception as e:
        return json.dumps({"error": str(e)})


# Example schema information
schema_info = {
    "SalesLT.Customer": {
        "CustomerID": "Integer",
        "NameStyle": "Boolean",
        "Title": "String(8)",
        "FirstName": "String(50)",
        "MiddleName": "String(50)",
        "LastName": "String(50)",
        "Suffix": "String(10)",
        "CompanyName": "String(128)",
        "SalesPerson": "String(256)",
        "EmailAddress": "String(50)",
        "Phone": "String(25)",
        "PasswordHash": "String(128)",
        "PasswordSalt": "String(10)",
        "rowguid": "UUID",
        "ModifiedDate": "DateTime",
    },
    "SalesLT.Product": {
        "ProductID": "Integer",
        "Name": "String(50)",
        "ProductNumber": "String(25)",
        "Color": "String(15)",
        "StandardCost": "Float",
        "ListPrice": "Float",
        "Size": "String(5)",
        "Weight": "DECIMAL(8,2)",
        "ProductCategoryID": "Integer",
        "ProductModelID": "Integer",
        "SellStartDate": "DateTime",
        "SellEndDate": "DateTime",
        "DiscontinuedDate": "DateTime",
        "ThumbNailPhoto": "BLOB",
        "ThumbnailPhotoFileName": "String(50)",
        "rowguid": "UUID",
        "ModifiedDate": "DateTime",
    },
}

# Sample user message
user_message = "Give me the top 5 products and their names in terms of sales"

# Define the messages
messages = [
    {"role": "system", "content": f"Schema information: {json.dumps(schema_info)}"},
    {"role": "user", "content": user_message},
]

# Define the tool
tools = [
    {
        "type": "function",
        "function": {
            "name": "execute_query",
            "description": "Execute a SQL query and return the results",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The SQL query to execute",
                    },
                },
                "required": ["query"],
            },
        },
    }
]

# Call the OpenAI API
response = client.chat.completions.create(
    model="gpt-4",  # replace with your model deployment name
    messages=messages,
    tools=tools,
    tool_choice="auto",
)

# Handle the function call response
response_message = response.choices[0].message
tool_calls = response_message.tool_calls

if tool_calls:
    available_functions = {
        "execute_query": execute_query,
    }

    for tool_call in tool_calls:
        function_name = tool_call.function.name
        function_to_call = available_functions[function_name]
        function_args = json.loads(tool_call.function.arguments)
        function_response = function_to_call(query=function_args.get("query"))
        print(f"Function Response: {function_response}")
else:
    print(f"Model Response: {response_message.content}")
