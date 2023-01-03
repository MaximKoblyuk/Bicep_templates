param log_analytics_name string
param data_producer_object_id string

var reader_role = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource log_analytics 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: log_analytics_name
  tags: {}
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

var cmf_object_id = 'e582bbd7-fc80-4ff6-b121-2b44afed4fa0'

resource cmf_sp 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(cmf_object_id, reader_role, log_analytics.name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', reader_role)
    principalId: cmf_object_id
  }
  scope: log_analytics
}

resource dataproducer_group 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(data_producer_object_id, reader_role, log_analytics.name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', reader_role)
    principalId: data_producer_object_id
  }
  scope: log_analytics
}

output la_id string = log_analytics.id
