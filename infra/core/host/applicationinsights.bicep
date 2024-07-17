param name string
param location string
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${name}-appinsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
  tags: tags
}
