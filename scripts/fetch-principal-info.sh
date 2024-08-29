#!/bin/bash

# Get the absolute path of the project root directory
PROJECT_ROOT=$(dirname "$(dirname "$(realpath "$0")")")
ENV_PATH="$PROJECT_ROOT/.env"

echo "Fetching Azure Principal ID and Name..."

# Fetch Principal ID
AZURE_PRINCIPAL_ID=$(az ad signed-in-user show --output tsv --query "id")
if [ -z "$AZURE_PRINCIPAL_ID" ]; then
    echo "Error: Failed to fetch Principal ID. Ensure you are logged in to Azure and have the necessary permissions."
    exit 1
fi
echo "Fetched Principal ID: $AZURE_PRINCIPAL_ID"

# Fetch Principal Name
AZURE_PRINCIPAL_NAME=$(az ad signed-in-user show --query userPrincipalName -o tsv)
if [ -z "$AZURE_PRINCIPAL_NAME" ]; then
    echo "Error: Failed to fetch Principal Name. Ensure you are logged in to Azure and have the necessary permissions."
    exit 1
fi
echo "Fetched Principal Name: $AZURE_PRINCIPAL_NAME"

# Append to .env file in the project root
if [ -e "$ENV_PATH" ] && [ -w "$ENV_PATH" ]; then
    echo "AZURE_PRINCIPAL_ID=$AZURE_PRINCIPAL_ID" >> "$ENV_PATH"
    echo "AZURE_PRINCIPAL_NAME=$AZURE_PRINCIPAL_NAME" >> "$ENV_PATH"
    echo "Principal ID and Name have been appended to the .env file in the root directory."
else
    echo "Error: Cannot write to $ENV_PATH. Check file permissions."
fi
