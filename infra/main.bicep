targetScope = 'subscription'

@allowed([
  'eastus'
  'eastus2'
  'westus'
])
param location string
param name string
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

module appService 'core/host/appservice.bicep' = {
  name: 'appServiceDeployment'
  scope: resourceGroup
  params: {
    name: name
    location: location
    tags: tags
  }
}

module sqlDatabase 'core/database/sql-database.bicep' = {
  name: 'sqlDatabaseDeployment'
  scope: resourceGroup
  params: {
    location: location
    serverName: '${name}-sql-server'
    databaseName: '${name}-database'
    administratorLogin: 'adminUser'
    administratorPassword: 'adminPassword'
    administratorAADId: 'aadId'
  }
}

module managedIdentity 'core/identity/user-mi.bicep' = {
  name: 'managedIdentityDeployment'
  scope: resourceGroup
  params: {
    name: name
    location: location
    tags: tags
  }
}

module openAIService 'core/ai/openai.bicep' = {
  name: 'openAIDeployment'
  scope: resourceGroup
  params: {
    name: name
    location: location

  }
}

module applicationInsights 'core/host/applicationInsights.bicep' = {
  name: 'applicationInsightsDeployment'
  scope: resourceGroup
  params: {
    name: name
    location: location
    tags: tags
  }
}

module roleAssignments 'core/identity/roleAssignments.bicep' = {
  name: 'roleAssignmentsDeployment'
  scope: resourceGroup
  params: {
    name: name
    openAIResourceId: openAIService.outputs.openAIResourceId
    sqlResourceId: sqlDatabase.outputs.sqlResourceId
    managedIdentityId: managedIdentity.outputs.managedIdentityId
  }
}


output resourceGroupName string = resourceGroup.name
output managedIdentityId string = managedIdentity.outputs.managedIdentityId
output openAIResourceId string = openAIService.outputs.openAIResourceId
