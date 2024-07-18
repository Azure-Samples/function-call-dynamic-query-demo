param name string
param location string
param chatgpt4oDeploymentCapacity int = 50


resource openAI 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: '${name}-openai'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
    capacity:chatgpt4oDeploymentCapacity
  }
  properties: {
    customSubDomainName: '${name}-openai'
  }
  resource gpt4o 'deployments' = {
    name: 'gpt-4o'
    properties: {
      model: {
        format: 'OpenAI'
        name: 'gpt-4o'
        version: '2024-05-13'
      }
    }
  }
}

output openAIResourceId string = openAI.id
