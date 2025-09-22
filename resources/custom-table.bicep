@description('Name of the Log Analytics workspace (existing)')
param workspaceName string = 'sqn-sentinel-01' 

var tableName = 'aitm_CL'

// Reference existing workspace in another resource group
resource existingWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
  // NOTE: Deploy this module at the workspace's resource group scope if different.
}

resource customTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  name: tableName
  parent: existingWorkspace
  properties: {
    schema: {
      name: tableName
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
      // plan: Basic vs Analytics not set here; defaults apply
    }
  // Using workspace default retention (omit property to inherit)
  }
}

output customTableName string = tableName
