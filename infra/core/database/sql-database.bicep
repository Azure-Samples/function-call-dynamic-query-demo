param location string
param serverName string
param databaseName string
param administratorLogin string
@secure()
param administratorPassword string
// param administratorAADId string
param tags object = {}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    // administrators: {
    //   administratorType: 'ActiveDirectory'
    //   principalType: 'User'
    //   azureADOnlyAuthentication: false
    //   login: 'abdulzedan'
    //   tenantId: subscription().tenantId
    //   // sid: administratorAADId
    // }
  }
  tags: tags
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    autoPauseDelay: 60
    readScale: 'Disabled'
    zoneRedundant: false
    sampleName: 'AdventureWorksLT'
  }
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  tags: tags
}

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2020-11-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output sqlResourceId string = sqlServer.id
output sqlResourcename string = sqlServer.name
output sqlHoutName string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output connectionString string = 'Driver={ODBC Driver 18 for SQL Server};Server=tcp:${sqlServer.properties.fullyQualifiedDomainName}.database.windows.net,1433;Database=${sqlDatabase.name};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30'
output sqlDatabaseuser string = administratorLogin
