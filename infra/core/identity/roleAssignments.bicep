param openAIResourceId string
param sqlResourceId string
param managedIdentityId string

resource openAIResource 'Microsoft.CognitiveServices/accounts@2021-04-01' existing = {
  name: openAIResourceId
}

resource sqlServerResource 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlResourceId
}

resource openAIRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentityId, openAIResourceId, '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  scope: openAIResource
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: managedIdentityId
  }
}

resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentityId, sqlResourceId, '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  scope: sqlServerResource
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: managedIdentityId
  }
}
