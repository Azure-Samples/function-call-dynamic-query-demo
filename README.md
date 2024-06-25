# FastAPI with Azure OpenAI and SQL Database Integration

This project demonstrates how to use FastAPI to create an API endpoint that interacts with Azure OpenAI and an Azure SQL database. The application allows you to send a message to the API, which then generates a SQL query, executes it against the database, and returns the results.

## Prerequisites

Before you begin, ensure you have the following:

- Python 3.8 or higher
- An Azure OpenAI account with API key and endpoint
- An Azure SQL Database with appropriate schema and data
- The following Python packages installed:
  - `fastapi`
  - `uvicorn`
  - `openai`
  - `azure-identity`
  - `pyodbc`
  - `python-dotenv`
  - `pydantic`

## Project Structure
.
├── app
│ ├── init.py
│ ├── main.py
│ ├── functions.py
│ └── routes.py
├── .env
├── example_run.py
├── testing_database_existency.py
├── README.md
└── requirements.txt


## Setup

1. Clone this repository to your local machine.

2. Create a virtual environment and activate it:

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`

pip install -r requirements.txt

AZURE_OPENAI_ENDPOINT=https://your_openai_endpoint
AZURE_OPENAI_API_KEY=your_openai_api_key
AZURE_SQL_CONNECTIONSTRING=DRIVER={ODBC Driver 17 for SQL Server};SERVER=your_sql_server;DATABASE=AdventureWorks

uvicorn app.main:app --reload



