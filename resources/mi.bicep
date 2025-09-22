@description('User Assigned Managed Identity name')
param identityName string

@description('Location for the managed identity')
param location string

@description('Data Collection Rule name (in same resource group) to scope Data Sender role')
param dcrName string

@description('Role definition ID for Data Collection Rule Data Sender (override if custom role is used)')
param dataSenderRoleId string = '3913510d-42f4-4e42-8a64-420c390055eb'
// Default maps to built-in role: Data Collection Rule Data Sender
// Docs: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#data-collection-rule-data-sender

@description('Storage account name to grant blob read access')
param storageAccountName string

// Built-in role definition IDs
var storageBlobDataReaderRoleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}


// Existing DCR in same resource group (scope narrowing)
resource targetDcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' existing = {
  name: dcrName
}

resource dcrDataSenderAssign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(targetDcr.id, uami.id, dataSenderRoleId)
  scope: targetDcr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', dataSenderRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Existing storage account for blob read scope
resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource storageBlobReaderAssign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(stg.id, uami.id, storageBlobDataReaderRoleId)
  scope: stg
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataReaderRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output identityClientId string = uami.properties.clientId
output identityPrincipalId string = uami.properties.principalId
output identityResourceId string = uami.id
