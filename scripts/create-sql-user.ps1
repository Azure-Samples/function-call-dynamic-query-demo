# Fetch environment variables
Write-Host "Fetching environment variables..."
$SQL_SERVER = azd env get-value SQL_SERVER
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to find a value for SQL_SERVER in your azd environment. Make sure you run azd up first."
    exit 1
}

$SQL_DATABASE = azd env get-value SQL_DATABASE
$APP_IDENTITY_NAME = azd env get-value MANAGED_IDENTITY_NAME

if (-not $SQL_SERVER -or -not $SQL_DATABASE -or -not $APP_IDENTITY_NAME) {
    Write-Host "Can't find SQL_SERVER, SQL_DATABASE, or AZURE_WEB_APP_NAME environment variables. Make sure you run azd up first."
    exit 1
}

Write-Host "Environment variables fetched successfully."
Write-Host "SQL_SERVER: $SQL_SERVER"
Write-Host "SQL_DATABASE: $SQL_DATABASE"
Write-Host "APP_IDENTITY_NAME: $APP_IDENTITY_NAME"


if (-Not (Test-Path -Path .\.venv)) {
    # Create Python virtual environment
    Write-Output 'Creating Python virtual environment in .venv...'
    python -m venv .venv

    # Activate the virtual environment
    Write-Output 'Activating the Python virtual environment...'
    . .\.venv\Scripts\Activate.ps1

    # Install dependencies from requirements.txt
    Write-Output 'Installing dependencies from "requirements.txt" into virtual environment...'
    .venv\Scripts\python -m pip install -r .\scripts\requirements.txt --quiet --disable-pip-version-check
} else {
    Write-Output 'Using existing Python virtual environment in .venv...'

    # Activate the virtual environment
    Write-Output 'Activating the Python virtual environment...'
    . .\.venv\Scripts\Activate.ps1

    # Install dependencies from requirements.txt
    Write-Output 'Installing dependencies from "requirements.txt" into virtual environment...'
    .venv\Scripts\python -m pip install -r .\scripts\requirements.txt --quiet --disable-pip-version-check
}


# Run the Python script to assign roles
Write-Host "Running the Python script to assign roles..."
python ./app/setup_sql_database_role.py --server $SQL_SERVER --database $SQL_DATABASE --app-identity-name $APP_IDENTITY_NAME
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to run the Python script."
    exit 1
}

Write-Host "Python script executed successfully."
