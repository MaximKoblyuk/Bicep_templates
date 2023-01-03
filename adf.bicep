param adf_name string
param log_analytics_workspace string

resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: adf_name
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
  }
}

var log_groups = [
  'ActivityRuns'
  'PipelineRuns'
  'TriggerRuns'
]

resource diagSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  scope: adf
  name: 'service'
  properties: {
    workspaceId: log_analytics_workspace
    logs: [for group in log_groups: {
      category: group
      enabled: true
    }]
  }
}
output object_id string = adf.identity.principalId
