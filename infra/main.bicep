targetScope = 'subscription'

@allowed([
  'eastus'
  'eastus2'
  'westus'
])
param location string
param name string
param tags object = {}

//sql param
param administratorLogin string
@secure()
param administratorPassword string


// app service
param appServicePlanName string
param appServiceSkuName string

// openai
param chatgpt4oDeploymentVersion string = '2024-05-13'
param chatgpt4oDeploymentName string = 'gpt-4o'



resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    sku: {
      name: appServiceSkuName
      capacity: 1
    }
    kind: 'linux'
  }
}

module appService 'core/host/appservice.bicep' = {
  name: 'appServiceDeployment'
  scope: resourceGroup
  params: {
    name: '${name}-webapp'
    location: location
    tags: union(tags, { 'azd-service-name': 'appdev' })
    appServicePlanId: appServicePlan.outputs.id
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    runtimeName: 'python'
    runtimeVersion: '3.10'
    appCommandLine: 'gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app'
    scmDoBuildDuringDeployment: true
    // githubRepo:'https://github.com/abdulzedan/function-call-dynamic-query-demo.git'
    // githubBranch: 'main'
    appSettings: {
      SQL_SERVER: sqlDatabase.outputs.sqlHostName
      SQL_DATABASE: sqlDatabase.outputs.sqlDatabaseName
      SQL_USERNAME: sqlDatabase.outputs.sqlDatabaseuser
      SQL_PASSWORD: administratorPassword
      AZURE_SQL_CONNECTIONSTRING: sqlDatabase.outputs.connectionString
      AZURE_CLIENT_ID: managedIdentity.outputs.managedIdentityPrincipalId
      AZURE_OPENAI_ENDPOINT: openAIService.outputs.openAIEndpoint
      AZURE_OPENAI_VERSION: chatgpt4oDeploymentVersion
      AZURE_OPENAI_CHAT_DEPLOYMENT: chatgpt4oDeploymentName
    }
  }
}




module sqlDatabase 'core/database/sql-database.bicep' = {
  name: 'sqlDatabaseDeployment'
  scope: resourceGroup
  params: {
    location: location
    serverName: '${name}-sql-server'
    databaseName: '${name}-database'
    administratorLogin: administratorLogin
    administratorPassword: administratorPassword
    // administratorAADId: 'aadId'
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

module applicationinsights 'core/host/applicationinsights.bicep' = {
  name: 'applicationInsightsDeployment'
  scope: resourceGroup
  params: {
    name: name
    location: location
    tags: tags
  }
}

// Assign Roles
module roleAssignments 'core/identity/roleAssignments.bicep' = {
  name: 'roleAssignmentsDeployment'
  scope: resourceGroup
  dependsOn: [
    openAIService
    sqlDatabase
    managedIdentity
  ]
  params: {
    openAIResourcename: openAIService.outputs.openAIResourceName
    sqlResourcename: sqlDatabase.outputs.sqlResourcename
    // managedIdentityId: managedIdentity.outputs.managedIdentityId
    managedIdentityPrincipalId: managedIdentity.outputs.managedIdentityPrincipalId
  }
}


output resourceGroupName string = resourceGroup.name
output managedIdentityId string = managedIdentity.outputs.managedIdentityId
output openAIResourceId string = openAIService.outputs.openAIResourceId
output SQL_SERVER string = sqlDatabase.outputs.sqlHostName
output SQL_DATABASE string = sqlDatabase.outputs.sqlDatabaseName
output APP_SERVICE_NAME string = appService.outputs.SERVICE_WEB_NAME
output ADMIN_USERNAME string = sqlDatabase.outputs.sqlDatabaseuser

