targetScope = 'subscription'

param location string
param resourceGroupName string
param serverName string
param databaseName string
param administratorLogin string
@secure()
param administratorPassword string
param appServicePlanName string
param webAppName string
param deployAzureOpenAI bool = true
@description('Specifies the login ID (Object ID) of a user in the Azure Active Directory tenant.')
param administratorAADId string


resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module sqlDatabase 'core/database/sql-database.bicep' = {
  name: 'sqlDatabase'
  scope: resourceGroup
  params: {
    location: location
    serverName: serverName
    databaseName: databaseName
    administratorLogin: administratorLogin
    administratorPassword: administratorPassword
    administratorAADId: administratorAADId
  }
}

module openAi 'core/ai/openai.bicep' = if (deployAzureOpenAI) {
  name: 'openAi'
  scope: resourceGroup
  params: {
    location: location
    resourceGroupName: resourceGroupName
  }
}

module appService 'core/host/app-service.bicep' = {
  name: 'appService'
  scope: resourceGroup
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppName: webAppName
  }
}

output sqlServerName string = sqlDatabase.outputs.sqlServerName
output sqlDatabaseName string = sqlDatabase.outputs.sqlDatabaseName
output appServicePlanName string = appService.outputs.appServicePlanName
output webAppName string = appService.outputs.webAppName
output webAppDefaultHostName string = appService.outputs.webAppDefaultHostName
output openAiEndpoint string = deployAzureOpenAI ? openAi.outputs.openAiEndpoint : ''
