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
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'https://github.com/your-repo/your-app/archive/refs/heads/main.zip'
        },
        {
          name: 'STARTUP_COMMAND'
          value: 'gunicorn -w 4 -k uvicorn.workers.UvicornWorker app:app'
        }
      ]
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
