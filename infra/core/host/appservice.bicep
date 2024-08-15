
param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param appServicePlanId string
param managedIdentityId string

// Runtime Properties
@allowed([
  'python'
])
param runtimeName string
param runtimeNameAndVersion string = '${runtimeName}|${runtimeVersion}'
param runtimeVersion string

// GitHub Deployment Properties
// param githubRepo string
// param githubBranch string = 'main'


// Microsoft.Web/sites Properties
param kind string = 'app,linux'

// Microsoft.Web/sites/config
param allowedOrigins array = []
param alwaysOn bool = true
param appCommandLine string = ''
@secure()
param appSettings object = {}
param clientAffinityEnabled bool = false
param scmDoBuildDuringDeployment bool = false
param use32BitWorkerProcess bool = false
param ftpsState string = 'FtpsOnly'
param healthCheckPath string = ''
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'

var msftAllowedOrigins = [ 'https://portal.azure.com', 'https://ms.portal.azure.com' ]



var coreConfig = {
  linuxFxVersion: runtimeNameAndVersion
  alwaysOn: alwaysOn
  ftpsState: ftpsState
  appCommandLine: appCommandLine
  minTlsVersion: '1.2'
  use32BitWorkerProcess: use32BitWorkerProcess
  healthCheckPath: healthCheckPath
  cors: {
    allowedOrigins: union(msftAllowedOrigins, allowedOrigins)
  }
}

var appServiceProperties = {
  serverFarmId: appServicePlanId
  siteConfig: coreConfig
  clientAffinityEnabled: clientAffinityEnabled
  httpsOnly: true
  publicNetworkAccess: publicNetworkAccess
}


resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${name}-asp'
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    capacity:1
  }
  tags: tags
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: appServiceProperties
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: union(appSettings,
      {
        SCM_DO_BUILD_DURING_DEPLOYMENT: string(scmDoBuildDuringDeployment)
      },
      runtimeName == 'python' ? { PYTHON_ENABLE_GUNICORN_MULTIWORKERS: 'true' } : {})
  }

  resource configLogs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: { fileSystem: { level: 'Verbose' } }
      detailedErrorMessages: { enabled: true }
      failedRequestsTracing: { enabled: true }
      httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
    }
    dependsOn: [
      configAppSettings
    ]
  }

  resource basicPublishingCredentialsPoliciesFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }

  resource basicPublishingCredentialsPoliciesScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }

//   resource configSourceControl 'sourcecontrols' = {
//     name: 'web'
//     properties: {
//       repoUrl: githubRepo
//       branch: githubBranch
//       isManualIntegration: false
//       isGitHubAction: true
//       deploymentRollbackEnabled: true
//     }
//   }
}





output SERVICE_WEB_NAME string = appService.name
output SERVICE_WEB_URI string = appService.properties.defaultHostName


output id string = appService.id
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output identityPrincipalId string = appService.identity.userAssignedIdentities[managedIdentityId].principalId
