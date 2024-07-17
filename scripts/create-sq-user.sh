#!/bin/bash

# Variables
serverName=$1
databaseName=$2
managedIdentityId=$3
resourceGroupName=$4
adminUser=$5
adminPassword=$6

# Create user and assign roles
sqlcmd -S $serverName.database.windows.net -d $databaseName -U $adminUser -P $adminPassword -Q "CREATE USER [$managedIdentityId] FROM EXTERNAL PROVIDER"
sqlcmd -S $serverName.database.windows.net -d $databaseName -U $adminUser -P $adminPassword -Q "ALTER ROLE db_datareader ADD MEMBER [$managedIdentityId]"
sqlcmd -S $serverName.database.windows.net -d $databaseName -U $adminUser -P $adminPassword -Q "ALTER ROLE db_datawriter ADD MEMBER [$managedIdentityId]"
