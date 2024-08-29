param name string
param location string
param chatgpt4oDeploymentCapacity int = 20
param openaideploymentname string = 'gpt-4o'
param openaimodelversion string = '2024-05-13'
param openaiApiVersion string = '2024-05-01-preview'
param customSubDomainName string = name


resource openAI 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
    tier: 'Standard'
    capacity: chatgpt4oDeploymentCapacity
  }
  properties: {
    customSubDomainName: customSubDomainName
  }
  resource gpt4o 'deployments' = {
    name: openaideploymentname
    sku: {
      name: 'Standard'
      capacity: 30
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: openaideploymentname
        version: openaimodelversion
      }
    }
  }
}

output openAIResourceId string = openAI.id
output openAIResourceName string = openAI.name
output openAIEndpoint string = openAI.properties.endpoint
output openAIDeploymentName string = openaideploymentname
output openAIDeploymentVersion string = openaimodelversion
output openAIAPIversion string = openaiApiVersion
output openAPItestingVersion string = openAI.apiVersion
