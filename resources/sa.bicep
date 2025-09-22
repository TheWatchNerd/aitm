@description('Storage account name')
param storageAccountName string

@description('Azure region')
param location string = resourceGroup().location

@description('Blob container name to host images')
param containerName string

resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: stg
  properties: {}
}

@description('Public blob container for the images')
resource imagesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: containerName
  parent: blobService
  properties: {
    publicAccess: 'Blob'
  }
}

output storageAccountId string = stg.id
output storageAccountName string = stg.name
output containerUrl string = 'https://${stg.name}.blob.${environment().suffixes.storage}/${containerName}'
