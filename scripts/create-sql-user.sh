#!/bin/bash

# Fetch environment variables
echo "Fetching environment variables..."
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

echo "Environment variables fetched successfully."
echo "SQL_SERVER: $SQL_SERVER"
echo "SQL_DATABASE: $SQL_DATABASE"
echo "APP_IDENTITY_NAME: $APP_IDENTITY_NAME"



###InstalL Oracle Driver######
if ! [[ "18.04 20.04 22.04 23.04 24.04" == *"$(lsb_release -rs)"* ]];
then
    echo "Ubuntu $(lsb_release -rs) is not currently supported.";
    exit;
fi

curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18

# Load the Python environment (if using a virtual environment)
echo "Loading Python environment..."
. ./scripts/load_python_env.sh
if [ $? -ne 0 ]; then
    echo "Failed to load Python environment."
    exit 1
fi

echo "Python environment loaded successfully."

# Run the Python script to assign roles
echo "Running the Python script to assign roles..."
python3 ./app/setup_sql_database_role.py --server $SQL_SERVER --database $SQL_DATABASE --app-identity-name $APP_IDENTITY_NAME
if [ $? -ne 0 ]; then
    echo "Failed to run the Python script."
    exit 1
fi

echo "Python script executed successfully."
