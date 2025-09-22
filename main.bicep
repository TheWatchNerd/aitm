@description('Deployment location')
param location string = resourceGroup().location

@description('Log Analytics Workspace name (existing)')
param workspaceName string

@description('Resource group containing the Log Analytics workspace')
param workspaceResourceGroup string

@description('Data Collection Rule name')
param dcrName string

@description('User-assigned managed identity name')
param identityName string

@description('Logic App name')
param logicAppName string

@description('Storage account name for images (must be globally unique)')
param storageAccountName string

@description('Container name for images')
param containerName string

@description('Custom table name (without _CL suffix)')
param customTableName string = 'aitm'

@description('Logical destination name inside the DCR for Log Analytics target')
param dcrDestinationName string = 'laDest'

@description('Name of the Azure Blob connection for Logic App')
param blobConnectionName string

// Deploy DCR (currently minimal – placeholder for future custom stream mapping)
module dcr 'resources/dcr.bicep' = {
  name: 'mod-dcr'
  params: {
    dcrName: dcrName
    location: location
    workspaceName: workspaceName
    workspaceResourceGroup: workspaceResourceGroup
    customTableName: customTableName
    destinationName: dcrDestinationName
  }
}

// Deploy managed identity & role assignment (RG scope)
module ingestIdentity 'resources/mi.bicep' = {
  name: 'mod-ingestIdentity'
  dependsOn: [ dcr ]
  params: {
    identityName: identityName
    location: location
    dcrName: dcrName
    storageAccountName: storageAccountName
  }
}

// Deploy storage (now separate from logic app)
module storage 'resources/sa.bicep' = {
  name: 'mod-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    containerName: containerName
  }
}

// Deploy logic app (loads definition from JSON) after identity (no direct dependency on storage unless workflow uses it)
module logicApp 'resources/logicapp.bicep' = {
  name: 'mod-logicApp'
  params: {
    logicAppName: logicAppName
    location: location
    userAssignedIdentityId: ingestIdentity.outputs.identityResourceId
    blobConnectionId: blobConnection.outputs.connectionId
    blobManagedApiId: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
    ingestionEndpoint: dcr.outputs.logIngestionUrl
    dcrImmutableId: dcr.outputs.dataCollectionRuleImmutableId
    customStreamName: dcr.outputs.customStreamName
    storageAccountName: storageAccountName
  }
}

module blobConnection 'resources/connection.bicep' = {
  name: 'mod-blobConnection'
  params: {
    connectionName: blobConnectionName
    location: location
    storageAccountName: storageAccountName
  }
}

output dataCollectionRuleId string = dcr.outputs.dataCollectionRuleId
output managedIdentityId string = ingestIdentity.outputs.identityResourceId
