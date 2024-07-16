param location string
param appServicePlanName string
param webAppName string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

output appServicePlanName string = appServicePlan.name
output webAppName string = webApp.name
output webAppDefaultHostName string = webApp.properties.defaultHostName
