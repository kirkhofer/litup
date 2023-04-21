targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param appServicePlanName string = ''
param resourceGroupName string = ''
param webServiceName string = ''
// serviceName is used as value for the tag (azd-service-name) azd uses to identify
param serviceName string = 'web'

// param webServiceName string = 'app-dai-${environmentName}-${take(location,24)}'

// Load the abbreviations.json file to use in resource names
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}
// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
    kind: 'linux'
    reserved: true
  }
}

// The application frontend
module web './core/host/appservice.bicep' = {
  name: serviceName
  scope: rg
  params: {
    name: !empty(webServiceName) ? webServiceName : '${abbrs.webSitesAppService}web-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.10'
    scmDoBuildDuringDeployment: true
    appCommandLine: 'python -m streamlit run app.py --server.port 8000 --server.address 0.0.0.0'
  }
}

// App outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output REACT_APP_WEB_BASE_URL string = web.outputs.uri

// Create an App Service Plan to group applications under the same payment plan and SKU
// module appServicePlan './core/host/appserviceplan.bicep' = {
//   name: appServicePlanName
//   scope: rg
//   params: {
//     name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}-${resourceToken}'
//     location: location
//     tags: tags
//     sku: {
//       name: 'B1'
//     }
//   }
// }

// // The application frontend
// module web './core/host/appservice.bicep' = {
//   name: webServiceName
//   scope: rg
//   params: {
//     name: !empty(webServiceName) ? webServiceName : '${abbrs.webSitesAppService}web-${resourceToken}'
//     location: location
//     tags: union(tags, { 'azd-service-name': webServiceName })
//     appServicePlanId: appServicePlan.outputs.id
//     runtimeName: 'python'
//     runtimeVersion: '3.10'
//     appCommandLine: 'python -m streamlit run app.py --server.port 8000 --server.address 0.0.0.0'
//     scmDoBuildDuringDeployment: true
//   }
// }

output resourceGroupName string = rg.name

