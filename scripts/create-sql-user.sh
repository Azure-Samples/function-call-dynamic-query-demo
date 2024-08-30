#!/bin/bash

# Fetch environment variables
echo "Fetching environment variables..."
SQL_SERVER=$(azd env get-value SQL_SERVER)
if [ $? -ne 0 ]; then
    echo "Failed to find a value for SQL_SERVER in your azd environment. Make sure you run azd up first."
    exit 1
fi

SQL_DATABASE=$(azd env get-value SQL_DATABASE)
APP_IDENTITY_NAME=$(azd env get-value MANAGED_IDENTITY_NAME)

if [ -z "$SQL_SERVER" ] || [ -z "$SQL_DATABASE" ] || [ -z "$APP_IDENTITY_NAME" ]; then
    echo "Can't find SQL_SERVER, SQL_DATABASE, or AZURE_WEB_APP_NAME environment variables. Make sure you run azd up first."
    exit 1
fi

echo "Environment variables fetched successfully."
echo "SQL_SERVER: $SQL_SERVER"
echo "SQL_DATABASE: $SQL_DATABASE"
echo "APP_IDENTITY_NAME: $APP_IDENTITY_NAME"

# Detect the OS version and install the appropriate Oracle driver
OS_ID=$(lsb_release -is)
OS_VERSION=$(lsb_release -rs)

if [ "$OS_ID" == "Ubuntu" ]; then
    echo "Detected OS: Ubuntu $OS_VERSION"
    if ! [[ "18.04 20.04 22.04 23.04 24.04" == *"$OS_VERSION"* ]]; then
        echo "Ubuntu $OS_VERSION is not currently supported."
        exit 1
    fi
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
    curl https://packages.microsoft.com/config/ubuntu/$OS_VERSION/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    sudo apt-get update
    sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
elif [ "$OS_ID" == "Debian" ]; then
    echo "Detected OS: Debian $OS_VERSION"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    if [ "$OS_VERSION" == "9" ]; then
        curl https://packages.microsoft.com/config/debian/9/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    elif [ "$OS_VERSION" == "10" ]; then
        curl https://packages.microsoft.com/config/debian/10/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    elif [ "$OS_VERSION" == "11" ]; then
        curl https://packages.microsoft.com/config/debian/11/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    elif [ "$OS_VERSION" == "12" ]; then
        curl https://packages.microsoft.com/config/debian/12/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    else
        echo "Debian $OS_VERSION is not currently supported."
        exit 1
    fi
    sudo apt-get update
    sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
    source ~/.bashrc
    sudo apt-get install -y unixodbc-dev
    sudo apt-get install -y libgssapi-krb5-2
else
    echo "Unsupported OS: $OS_ID $OS_VERSION"
    exit 1
fi

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
