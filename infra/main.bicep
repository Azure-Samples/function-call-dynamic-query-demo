targetScope = 'subscription'

@allowed([
  'eastus'
  'eastus2'
  'westus'
])
param location string
param name string
param tags object = {}
param administratorLogin string
@secure()
param administratorPassword string

param appServicePlanName string
param appServiceSkuName string


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

// Create an App Service Plan to group applications under the same payment plan and SKU


module appService 'core/host/appservice.bicep' = {
  name: 'appServiceDeployment'
  scope: resourceGroup
  params: {
    name: '${name}-webapp'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    runtimeName: 'python'
    runtimeVersion: '3.11'
    appCommandLine: './scripts/start.sh'
    scmDoBuildDuringDeployment: true
    githubRepo:'https://github.com/abdulzedan/function-call-dynamic-query-demo.git'
    githubBranch: 'main'
    appSettings: {
      SQL_SERVER: '$(SQL_SERVER)'
      SQL_DATABASE: '$(SQL_DATABASE)'
      SQL_USERNAME: '$(SQL_USERNAME)'
      SQL_PASSWORD: '$(SQL_PASSWORD)'
      AZURE_SQL_CONNECTIONSTRING: '$(AZURE_SQL_CONNECTIONSTRING)'
      AZURE_OPENAI_API_KEY: '$(AZURE_OPENAI_API_KEY)'
      AZURE_OPENAI_ENDPOINT: '$(AZURE_OPENAI_ENDPOINT)'
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

