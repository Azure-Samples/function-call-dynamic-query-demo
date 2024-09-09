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
OS=$(uname)
if [ "$OS" == "Linux" ]; then
    OS_ID=$(lsb_release -is 2>/dev/null)
    OS_VERSION=$(lsb_release -rs 2>/dev/null)

    if [ "$OS_ID" == "Debian" ]; then
        echo "Detected OS: Debian $OS_VERSION"

        # Skip installing libldap-2.5-0 if dependencies cannot be met
        if ! dpkg -s libldap-2.5-0 &>/dev/null; then
            echo "Skipping installation of libldap-2.5-0 due to unmet dependencies."
        else
            echo "Installing libldap-2.5-0..."
            dpkg -i libldap-2.5-0_2.5.13+dfsg-5_amd64.deb
            if [ $? -ne 0 ]; then
                echo "Failed to install libldap-2.5-0. Skipping further libldap installation."
            else
                dpkg -i libldap-dev_2.5.13+dfsg-5_amd64.deb
            fi
        fi

        # Add GPG key and configure repository
        echo "Adding GPG key and configuring repository..."
        if [ "$OS_VERSION" == "9" ] || [ "$OS_VERSION" == "10" ] || [ "$OS_VERSION" == "11" ]; then
            curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
        elif [ "$OS_VERSION" == "12" ]; then
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
        else
            echo "Debian $OS_VERSION is not currently supported."
            exit 1
        fi

        # Configure repository based on Debian version
        echo "Configuring repository based on Debian version..."
        curl https://packages.microsoft.com/config/debian/$OS_VERSION/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

        # Clear APT cache and update
        echo "Clearing APT cache and updating..."
        sudo rm -rf /var/lib/apt/lists/*
        sudo apt-get update

        # Install ODBC driver and tools
        echo "Installing ODBC driver and tools..."
        sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18
        echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
        source ~/.bashrc

        # Install unixODBC development headers and kerberos library
        echo "Installing unixODBC development headers and kerberos library..."
        sudo apt-get install -y unixodbc-dev libgssapi-krb5-2

    elif [ "$OS_ID" == "Ubuntu" ]; then
        echo "Detected OS: Ubuntu $OS_VERSION"
        if ! [[ "18.04 20.04 22.04 23.04 24.04" == *"$OS_VERSION"* ]]; then
            echo "Ubuntu $OS_VERSION is not currently supported."
            exit 1
        fi

        # Add GPG key and configure repository
        echo "Adding GPG key and configuring repository..."
        curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
        curl https://packages.microsoft.com/config/ubuntu/$OS_VERSION/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

        # Clear APT cache and update
        echo "Clearing APT cache and updating..."
        sudo rm -rf /var/lib/apt/lists/*
        sudo apt-get update

        # Install ODBC driver and tools
        echo "Installing ODBC driver and tools..."
        sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18
        echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
        source ~/.bashrc

        # Install unixODBC development headers and kerberos library
        echo "Installing unixODBC development headers and kerberos library..."
        sudo apt-get install -y unixodbc-dev libgssapi-krb5-2

    else
        echo "Unsupported Linux distribution."
        exit 1
    fi

elif [ "$OS" == "Darwin" ]; then
    echo "Detected OS: macOS"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
    brew update
    HOMEBREW_ACCEPT_EULA=Y brew install msodbcsql18 mssql-tools18
    echo 'export PATH="/usr/local/opt/msodbcsql18/bin:/usr/local/opt/mssql-tools18/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
else
    echo "Unsupported OS: $OS"
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
