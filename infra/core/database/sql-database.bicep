param location string
param serverName string
param databaseName string
param administratorLogin string
@secure()
param administratorPassword string
// param administratorAADId string
param tags object = {}

// parameters for aad
param aad_admin_type string = 'User'
param aad_only_auth bool = false
@description('The name of the Azure AD admin for the SQL server.')
param aad_admin_name string
@description('The Tenant ID of the Azure Active Directory')
param aad_admin_tenantid string = subscription().tenantId
@description('The Object ID of the Azure AD admin.')
param aad_admin_objectid string

// referenced properties:
// Reference Properties

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      login: aad_admin_name
      sid: aad_admin_objectid
      tenantId: aad_admin_tenantid
      principalType: aad_admin_type
      azureADOnlyAuthentication: aad_only_auth

      // sid: administratorAADId
    }
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
  name: 'AllowAlLinternalAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource firewallRule_Azure 'Microsoft.Sql/servers/firewallRules@2020-11-01-preview' = {
  parent: sqlServer
  name: 'AllowAllIps'
  properties: {
    endIpAddress:'255.255.255.255'
    startIpAddress:  '0.0.0.0'
  }
}


output sqlResourceId string = sqlServer.id
output sqlResourcename string = sqlServer.name
output sqlHostName string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output connectionString string = 'Driver={ODBC Driver 18 for SQL Server};Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlDatabase.name};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30'
output sqlDatabaseuser string = administratorLogin
