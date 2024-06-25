import os
import json
from fastapi import FastAPI, Request, HTTPException
from openai import AzureOpenAI
from dotenv import load_dotenv
from .functions import execute_query
from .routes import router
import logging
from pydantic import BaseModel

class AskRequest(BaseModel):
    message: str

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

app = FastAPI()

app.include_router(router)  # Include the router

# Define the Azure OpenAI client
client = AzureOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_version="2024-03-01-preview"
)

# Schema information for the tables
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
        "ModifiedDate": "DateTime"
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
        "ModifiedDate": "DateTime"
    }
}

# Root endpoint for testing
@app.get("/")
async def root():
    return {"message": "Hello, World!"}
@app.post("/ask/")
async def ask_openai(request: AskRequest):
    try:
        user_message = request.message

        if not user_message:
            raise HTTPException(status_code=400, detail="Message is required")

        messages = [
            {"role": "system", "content": f"Schema information: {json.dumps(schema_info)}"},
            {"role": "user", "content": user_message}
        ]

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

        response = client.chat.completions.create(
            model="gpt-4",  # replace with your model deployment name
            messages=messages,
            tools=tools,
            tool_choice="auto",
        )

        logger.info(f"Received response: {response}")

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
                logger.info(f"Function arguments: {function_args}")
                function_response = function_to_call(
                    query=function_args.get("query")
                )
                logger.info(f"Function Response: {function_response}")
                return json.loads(function_response)
        else:
            logger.info(f"Model Response: {response_message.content}")
            return {"response": response_message.content}

    except Exception as e:
        logger.error(f"Error processing request: {e}")
        raise HTTPException(status_code=500, detail=str(e))
