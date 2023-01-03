param app_insights_name string
param la_id string

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: app_insights_name
  location: resourceGroup().location
  kind: 'other'
  properties: {
    Flow_Type: 'Bluefield'
    Application_Type: 'other'
    DisableIpMasking: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    WorkspaceResourceId: la_id
  }
}

output appinsightsConnectionString string = appinsights.properties.ConnectionString
