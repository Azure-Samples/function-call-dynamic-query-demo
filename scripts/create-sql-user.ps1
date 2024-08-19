# Fetch environment variables
$SQL_SERVER = azd env get-value SQL_SERVER
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to find a value for SQL_SERVER in your azd environment. Make sure you run azd up first."
    exit 1
}

$SQL_DATABASE = azd env get-value SQL_DATABASE
$APP_IDENTITY_NAME = azd env get-value AZURE_WEB_APP_NAME

if (-not $SQL_SERVER -or -not $SQL_DATABASE -or -not $APP_IDENTITY_NAME) {
    Write-Host "Can't find SQL_SERVER, SQL_DATABASE, or AZURE_WEB_APP_NAME environment variables. Make sure you run azd up first."
    exit 1
}

# Run the Python script to assign roles
python3 ./app/setup_sql_azurerole.py --server $SQL_SERVER --database $SQL_DATABASE --app-identity-name $APP_IDENTITY_NAME