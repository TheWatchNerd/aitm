@description('Name of the Logic App (Consumption)')
param logicAppName string

@description('Azure region')
param location string = resourceGroup().location

// Storage now deployed via separate sa.bicep module

@description('Resource ID of the user-assigned managed identity to attach')
param userAssignedIdentityId string

// Load external workflow definition JSON (definition only; we'll override parameter values dynamically)
var workflowFile = loadTextContent('logicappcode.json')
@description('Original workflow JSON parsed')
var workflowJson = json(workflowFile)

@description('Azure Blob connection resource ID (Microsoft.Web/connections)')
param blobConnectionId string

@description('Azure Blob managed API id (locations/managedApis/azureblob)')
param blobManagedApiId string

@description('Logs ingestion endpoint base URL from DCR (e.g. https://<dcr>.<region>.ingest.monitor.azure.com)')
param ingestionEndpoint string = ''

@description('Immutable ID of the Data Collection Rule (for path construction)')
param dcrImmutableId string = ''

@description('Custom stream name, e.g. Custom-aitm_CL')
param customStreamName string = ''

@description('Storage account name for blob dataset resolution in workflow')
param storageAccountName string = ''

// Compose ingestion URI if parameters provided
var composedIngestionUri = (!empty(ingestionEndpoint) && !empty(dcrImmutableId) && !empty(customStreamName)) ? '${ingestionEndpoint}/dataCollectionRules/${dcrImmutableId}/streams/${customStreamName}?api-version=2023-01-01' : ''
// Replace placeholder tokens in raw JSON (placeholders defined in logicappcode.json)
var withUri = empty(composedIngestionUri) ? workflowFile : replace(workflowFile, '__INGESTION_URI__', composedIngestionUri)
var withIdentity = replace(withUri, '__UAMI_ID__', userAssignedIdentityId)
var withStorage = empty(storageAccountName) ? withIdentity : replace(withIdentity, '__STORAGE_ACCOUNT__', storageAccountName)
var finalWorkflow = json(withStorage)


resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
  definition: finalWorkflow.definition
    parameters: union(workflowJson.parameters, {
      '$connections': {
        type: 'Object'
        value: {
          azureblob: {
            connectionId: blobConnectionId
            connectionName: split(blobConnectionId, '/')[length(split(blobConnectionId, '/')) - 1]
            id: blobManagedApiId
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
                identity: userAssignedIdentityId
              }
            }
          }
        }
      }
    })
  }
}
