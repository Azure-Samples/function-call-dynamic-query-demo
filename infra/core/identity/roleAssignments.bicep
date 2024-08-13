param openAIResourceId string
param sqlResourceId string
// param managedIdentityId string
param managedIdentityPrincipalId string

param roledefinitionopenai string = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
param roledefinitionsql string = '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'


resource openAIResource 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: openAIResourceId
}

resource sqlServerResource 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlResourceId
}

resource openAIRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, managedIdentityPrincipalId, roledefinitionopenai)
  scope: openAIResource
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roledefinitionopenai)
    principalId: managedIdentityPrincipalId
  }
}

resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, managedIdentityPrincipalId, roledefinitionsql)
  scope: sqlServerResource
  properties: {

    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roledefinitionsql)
    principalId: managedIdentityPrincipalId
  }
}

// Add these outputs for debugging
output openAIResourceIdOut string = openAIResource.id
output sqlResourceIdOut string = sqlServerResource.id
