// param location string
// param resourceGroupName string
// param deployAzureOpenAI bool = true

// resource openAiResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
//   name: resourceGroupName
// }

// resource openAi 'Microsoft.CognitiveServices/accounts@2021-04-30' = if (deployAzureOpenAI) {
//   name: 'openai-gpt4o'
//   location: location
//   kind: 'OpenAI'
//   sku: {
//     name: 'S0'
//   }
//   properties: {
//     capabilities: [
//       {
//         name: 'GPT-4o'
//       }
//     ]
//   }
// }

// output openAiEndpoint string = openAi.properties.endpoint
