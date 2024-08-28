# Get the absolute path of the project root directory
$projectRoot = Split-Path -Parent (Split-Path -Parent (Resolve-Path $MyInvocation.MyCommand.Path))
$envPath = "$projectRoot\.env"

Write-Host "Fetching Azure Principal ID and Name..."

# Fetch Principal ID
$principalId = az ad signed-in-user show --query id -o tsv
if (-not $principalId) {
    Write-Host "Error: Failed to fetch Principal ID. Ensure you are logged in to Azure and have the necessary permissions."
    exit 1
}
Write-Host "Fetched Principal ID: $principalId"

# Fetch Principal Name
$principalName = az ad signed-in-user show --query userPrincipalName -o tsv
if (-not $principalName) {
    Write-Host "Error: Failed to fetch Principal Name. Ensure you are logged in to Azure and have the necessary permissions."
    exit 1
}
Write-Host "Fetched Principal Name: $principalName"

# Append to .env file in the project root
if (Test-Path $envPath) {
    Add-Content $envPath "AZURE_PRINCIPAL_ID=$principalId"
    Add-Content $envPath "AZURE_PRINCIPAL_NAME=$principalName"
    Write-Host "Principal ID and Name have been appended to the .env file in the root directory."
} else {
    Write-Host "Error: The .env file does not exist or is not accessible."
}
