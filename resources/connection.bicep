@description('Logic App connection name')
param connectionName string

@description('Location (must match Logic App region)')
param location string = resourceGroup().location

@description('Target storage account name for blob operations')
param storageAccountName string

resource storageConnection 'Microsoft.Web/connections@2015-08-01-preview' = {
  name: connectionName
  location: location
  kind: 'V1'
  properties: {
    displayName: 'con-${storageAccountName}-blob-mi'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
      location: location
    }
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {}
    }
}
}

output connectionId string = storageConnection.id
