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
// parameters for aad
param aad_admin_type string = 'User'
param aad_only_auth bool = false
@description('The name of the Azure AD admin for the SQL server.')
param aad_admin_name string
@description('The Tenant ID of the Azure Active Directory')
param aad_admin_tenantid string = subscription().tenantId
@description('The Object ID of the Azure AD admin.')
param aad_admin_objectid string


// app service
param appServicePlanName string = ''
param appServiceSkuName string


var resourceToken = toLower(uniqueString(subscription().id, name, location))
var prefix = '${name}-${resourceToken}'


resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${prefix}-plan'
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
    name: '${prefix}-webapp'
    location: location
    tags: union(tags, { 'azd-service-name': 'appdev' })
    appServicePlanId: appServicePlan.outputs.id
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    runtimeName: 'python'
    runtimeVersion: '3.10'
    appCommandLine: 'entrypoint.sh'
    scmDoBuildDuringDeployment: true
    // githubRepo:'https://github.com/abdulzedan/function-call-dynamic-query-demo.git'
    // githubBranch: 'main'
    appSettings: {
      SQL_SERVER: sqlDatabase.outputs.sqlHostName
      SQL_DATABASE: sqlDatabase.outputs.sqlDatabaseName
      SQL_USERNAME: sqlDatabase.outputs.sqlDatabaseuser
      SQL_PASSWORD: administratorPassword
      AZURE_SQL_CONNECTIONSTRING: sqlDatabase.outputs.connectionString
      AZURE_CLIENT_ID: managedIdentity.outputs.managedIdentityClientId
      AZURE_OPENAI_ENDPOINT: openAIService.outputs.openAIEndpoint
      AZURE_OPENAI_VERSION: openAIService.outputs.openAIAPIversion
      AZURE_OPENA_MODEL_VERSION: openAIService.outputs.openAIDeploymentVersion
      AZURE_OPENAI_CHAT_DEPLOYMENT: openAIService.outputs.openAIDeploymentName
    }
  }
}




module sqlDatabase 'core/database/sql-database.bicep' = {
  name: 'sqlDatabaseDeployment'
  scope: resourceGroup
  params: {
    aad_admin_name: aad_admin_name
    aad_admin_objectid: aad_admin_objectid
    aad_admin_tenantid: aad_admin_tenantid
    aad_only_auth: aad_only_auth
    aad_admin_type: aad_admin_type
    location: location
    serverName: '${prefix}-sql-server'
    databaseName: '${prefix}-database'
    administratorLogin: administratorLogin
    administratorPassword: administratorPassword
    // administratorAADId: 'aadId'
  }
}

module managedIdentity 'core/identity/user-mi.bicep' = {
  name: 'managedIdentityDeployment'
  scope: resourceGroup
  params: {
    name: '${prefix}-identity'
    location: location
    tags: tags
  }
}

module openAIService 'core/ai/openai.bicep' = {
  name: 'openAIDeployment'
  scope: resourceGroup
  params: {
    name: '${prefix}-openai'
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
output AZURE_WEB_APP_NAME string = appService.outputs.SERVICE_WEB_NAME
output ADMIN_USERNAME string = sqlDatabase.outputs.sqlDatabaseuser
output MANAGED_IDENTITY_NAME string = managedIdentity.outputs.managedIdentityName
