@description('Data Collection Rule name')
param dcrName string

@description('Target region (must match workspace region)')
param location string

@description('Existing Log Analytics workspace name')
param workspaceName string

@description('Resource group containing the Log Analytics workspace')
param workspaceResourceGroup string

@description('Custom table name (without _CL suffix)')
param customTableName string = 'aitm'

@description('Destination name label inside the DCR (logical identifier)')
param destinationName string = 'laDest'

var streamName = 'Custom-${customTableName}_CL'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
  scope: resourceGroup(workspaceResourceGroup)
}

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  kind: 'Direct'
  properties: {
    dataCollectionEndpointId: null
    streamDeclarations: {
      '${streamName}': {
        columns: [
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }
          {
            name: 'Accept_s'
            type: 'string'
          }
          {
            name: 'AcceptEncoding_s'
            type: 'string'
          }
          {
            name: 'AcceptLanguage_s'
            type: 'string'
          }
          {
            name: 'Host_s'
            type: 'string'
          }
          {
            name: 'MaxForwards_s'
            type: 'string'
          }
          {
            name: 'Referer_s'
            type: 'string'
          }
          {
            name: 'UserAgent_s'
            type: 'string'
          }
          {
            name: 'sec_ch_ua_platform_s'
            type: 'string'
          }
          {
            name: 'sec_ch_ua_s'
            type: 'string'
          }
          {
            name: 'sec_ch_ua_mobile_s'
            type: 'string'
          }
          {
            name: 'SecFetchSite_s'
            type: 'string'
          }
          {
            name: 'SecFetchMode_s'
            type: 'string'
          }
          {
            name: 'SecFetchDest_s'
            type: 'string'
          }
          {
            name: 'SecFetchStorageAccess_s'
            type: 'string'
          }
          {
            name: 'X_ARR_LOG_ID_s'
            type: 'string'
          }
          {
            name: 'CLIENT_IP_s'
            type: 'string'
          }
          {
            name: 'DISGUISED_HOST_s'
            type: 'string'
          }
          {
            name: 'X_SITE_DEPLOYMENT_ID_s'
            type: 'string'
          }
          {
            name: 'WAS_DEFAULT_HOSTNAME_s'
            type: 'string'
          }
          {
            name: 'X_Forwarded_Proto_s'
            type: 'string'
          }
          {
            name: 'X_AppService_Proto_s'
            type: 'string'
          }
          {
            name: 'X_ARR_SSL_s'
            type: 'string'
          }
          {
            name: 'X_Forwarded_TlsVersion_s'
            type: 'string'
          }
          {
            name: 'X_Forwarded_For_s'
            type: 'string'
          }
          {
            name: 'X_Original_URL_s'
            type: 'string'
          }
          {
            name: 'X_WAWS_Unencoded_URL_s'
            type: 'string'
          }
          {
            name: 'RawIngestionTime_t'
            type: 'datetime'
          }
        ]
      }
    }
    destinations: {
      logAnalytics: [
        {
          name: destinationName
          workspaceResourceId: workspace.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [streamName]
        destinations: [destinationName]
        transformKql: 'source'
        outputStream: 'Custom-${customTableName}_CL'
      }
    ]
  }
}

output dataCollectionRuleId string = dcr.id
output logIngestionUrl string = dcr.properties.endpoints.logsIngestion
output dataCollectionRuleImmutableId string = dcr.properties.immutableId
output customStreamName string = streamName
