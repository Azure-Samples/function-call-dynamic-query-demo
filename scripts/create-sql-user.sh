#!/bin/bash

# Fetch environment variables
SQL_SERVER=$(azd env get-value SQL_SERVER)
if [ $? -ne 0 ]; then
    echo "Failed to find a value for SQL_SERVER in your azd environment. Make sure you run azd up first."
    exit 1
fi

SQL_DATABASE=$(azd env get-value SQL_DATABASE)
APP_IDENTITY_NAME=$(azd env get-value AZURE_WEB_APP_NAME)

if [ -z "$SQL_SERVER" ] || [ -z "$SQL_DATABASE" ] || [ -z "$APP_IDENTITY_NAME" ]; then
    echo "Can't find SQL_SERVER, SQL_DATABASE, or AZURE_WEB_APP_NAME environment variables. Make sure you run azd up first."
    exit 1
fi

# Load the Python environment (if using a virtual environment)
# . ./scripts/load_python_env.sh

. ./scripts/load_python_env.sh

# Run the Python script to assign roles
python3 ./app/setup_sql_azurerole.py --server $SQL_SERVER --database $SQL_DATABASE --app-identity-name $APP_IDENTITY_NAME
