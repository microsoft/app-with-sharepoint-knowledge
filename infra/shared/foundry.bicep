param name string
param location string = resourceGroup().location
param tags object = {}
param identityId string
param identityPrincipalId string
param deploymentName string = 'gpt-4o'
param modelName string = 'gpt-4o'
param modelVersion string = '2024-08-06'
param deploymentCapacity int = 10

resource cognitiveAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: cognitiveAccount
  name: deploymentName
  sku: {
    name: 'Standard'
    capacity: deploymentCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}

// Cognitive Services OpenAI User role definition ID
// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#cognitive-services-openai-user
var cognitiveServicesOpenAIUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

// Grant the managed identity access to the Azure OpenAI service
resource openAIRoleAssignmentForManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cognitiveAccount.id, identityPrincipalId, cognitiveServicesOpenAIUserRoleId)
  scope: cognitiveAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRoleId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output endpoint string = cognitiveAccount.properties.endpoint
output id string = cognitiveAccount.id
output name string = cognitiveAccount.name
output playgroundUrl string = '${cognitiveAccount.properties.endpoint}openai/deployments/${deploymentName}'
output modelName string = modelName
