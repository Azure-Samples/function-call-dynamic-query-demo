param name string
param openAIResourceId string
param sqlResourceId string
param managedIdentityId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedIdentityId, openAIResourceId, 'OpenAIServiceRole')
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalId: managedIdentityId
    principalType: 'ServicePrincipal'
    scope: openAIResourceId
  }
}

resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedIdentityId, sqlResourceId, 'SQLServiceRole')
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Adjust to the appropriate role
    principalId: managedIdentityId
    principalType: 'ServicePrincipal'
    scope: sqlResourceId
  }
}
