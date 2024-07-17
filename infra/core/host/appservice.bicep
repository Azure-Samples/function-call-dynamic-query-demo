param name string
param location string
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${name}-asp'
  location: location
  sku: {
    name: 'P1v2'
    tier: 'PremiumV2'
    size: 'P1v2'
  }
  tags: tags
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: '${name}-webapp'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.8'
    }
    httpsOnly: true
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${name}-identity': {}
    }
  }
  tags: tags
}

resource webAppConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'web'
  parent: webApp
  properties: {
    appSettings: [
      {
        name: 'WEBSITE_RUN_FROM_PACKAGE'
        value: 'https://github.com/your-repo/your-app/archive/refs/heads/main.zip'
      }
      {
        name: 'STARTUP_COMMAND'
        value: './scripts/start.sh'
      }
      {
        name: 'SQL_SERVER'
        value: '$(SQL_SERVER)'
      }
      {
        name: 'SQL_DATABASE'
        value: '$(SQL_DATABASE)'
      }
      {
        name: 'SQL_USERNAME'
        value: '$(SQL_USERNAME)'
      }
      {
        name: 'SQL_PASSWORD'
        value: '$(SQL_PASSWORD)'
      }
      {
        name: 'AZURE_SQL_CONNECTIONSTRING'
        value: '$(AZURE_SQL_CONNECTIONSTRING)'
      }
      {
        name: 'AZURE_OPENAI_API_KEY'
        value: '$(AZURE_OPENAI_API_KEY)'
      }
      {
        name: 'AZURE_OPENAI_ENDPOINT'
        value: '$(AZURE_OPENAI_ENDPOINT)'
      }
    ]
  }
}
