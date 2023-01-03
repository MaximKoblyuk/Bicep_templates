param eventhub object
param layers array
param keyvaults array
param opco_name string
param env string
param databricks_workspaces array
param data_producer_role object
param data_quality_groups array
param data_explorer object

var base_name = 'lh-${opco_name}-${env}'

var base_name_simple = 'lh${opco_name}${env}'
targetScope = 'subscription'

var service_endpoints = [
  'Microsoft.Storage'
  'Microsoft.KeyVault'
  'Microsoft.EventHub'
]
var service_endpoint_objs = [for service_endpoint in service_endpoints: {
  'service': service_endpoint
}]

var private_subnets = [for (databricks_workspace, i) in databricks_workspaces: {
  'name': 'db-private-${databricks_workspace.name}'
  'properties': {
    'addressPrefix': '172.16.${i * 2}.0/24'
    'serviceEndpoints': service_endpoint_objs
  }
}]
var public_subnets = [for (databricks_workspace, i) in databricks_workspaces: {
  'name': 'db-public-${databricks_workspace.name}'
  'properties': {
    'addressPrefix': '172.16.${(i * 2) + 1}.0/24'
    'serviceEndpoints': service_endpoint_objs
  }
}]

var subnets = concat(private_subnets, public_subnets)

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'ahtech-${base_name}'
  location: 'westeurope'
}

var thor_reader_object_id = '7e494288-f09f-48f5-9fb3-edfe93bf91da' // TODO: Move to config
var reader_role = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var thor_contoller_object_id = 'ba7ae7d5-4e50-4984-b2c0-a4c2a19162e1' // TODO: Move to config
var controller_role = '72fafb9e-0641-4937-9268-a91bfd8191a3'

resource assignmentResource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(thor_reader_object_id, reader_role, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', reader_role)
    principalId: thor_reader_object_id
  }
}

resource symbolicname 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(thor_contoller_object_id, controller_role, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', controller_role)
    principalId: thor_contoller_object_id
  }
}

module log_analytics 'monitoring/log_analytics.bicep' = {
  name: 'log_analytics'
  params: {
    log_analytics_name: 'ahtech-${base_name}-la'
    data_producer_object_id: data_producer_role.object_id
  }
  scope: rg
}

module data_explorer_cluster 'monitoring/data_explorer.bicep' = if (!empty(data_explorer) && !contains(data_explorer, 'existing_instance')) {
  name: 'data_explorer_cluster'
  params: {
    data_explorer_name: 'ahtech${base_name_simple}de'
    configuration: data_explorer
    la_workspace: log_analytics.outputs.la_id
  }
  scope: rg
}

// Get connection strings to the data explorer per deployment type
var new_data_explorer_connection_string_ingest = !empty(data_explorer) && !contains(data_explorer, 'existing_instance') ? data_explorer_cluster.outputs.dataexplorer_ingest_connectionstring : ''
var existing_data_explorer_connection_string_ingest = !empty(data_explorer) && contains(data_explorer, 'existing_instance') ? data_explorer.existing_instance.connection_string_ingest : ''
var data_explorer_connection_string_ingest = !empty(new_data_explorer_connection_string_ingest) ? new_data_explorer_connection_string_ingest : !empty(existing_data_explorer_connection_string_ingest) ? existing_data_explorer_connection_string_ingest : 'not available'


var new_data_explorer_connection_string_query = !empty(data_explorer) && !contains(data_explorer, 'existing_instance') ? data_explorer_cluster.outputs.dataexplorer_uri : ''
var existing_data_explorer_connection_string_query = !empty(data_explorer) && contains(data_explorer, 'existing_instance') && contains(data_explorer.existing_instance, 'connection_string_query') ? data_explorer.existing_instance.connection_string_query : ''
var data_explorer_connection_string_query = !empty(new_data_explorer_connection_string_query) ? new_data_explorer_connection_string_query : !empty(existing_data_explorer_connection_string_query) ? existing_data_explorer_connection_string_query : 'not available'

module action_groups 'monitoring/dq_actionGroups.bicep' = {
  name: 'action_groups'
  params: {
    opcoName: opco_name
    environment: env
    actionGroupsArray: data_quality_groups
  }
  scope: rg
}

module alerts 'monitoring/dq_alerts.bicep' = {
  name: 'alerts'
  params: {
    logAnalyticsId: log_analytics.outputs.la_id
    opcoName: opco_name
    environment: env
    dqGroups: data_quality_groups
  }
  scope: rg
  dependsOn: [
    action_groups
    log_analytics
  ]
}

module app_insights 'monitoring/app_insights.bicep' = {
  name: 'app_insights'
  params: {
    app_insights_name: 'ahtech-${base_name}-ai'
    la_id: log_analytics.outputs.la_id
  }
  scope: rg
}

module dq_dashboard 'monitoring/dq_dashboard.json' = {
  name: 'dq_dashboard'
  params: {
    dashboard_name: 'ahtech-${base_name}-dashboard-dq'
    la_id: log_analytics.outputs.la_id
  }
  scope: rg
}

module nsg 'networking/databricks_nsg.bicep' = {
  name: 'lockheed_databricks_nsg'
  params: {
    nsg_name: 'ahtech-${base_name}-db-nsg'
  }
  scope: rg
}

module vnet 'networking/vnet.bicep' = {
  name: 'lockheed_vnet'
  params: {
    vnet_name: 'ahtech-${base_name}-vnet'
    subnets: subnets
    nsg_id: nsg.outputs.nsg_id
  }
  scope: rg
}

var subnet_ids = [for subnet in subnets: '${rg.id}/providers/Microsoft.Network/virtualNetworks/ahtech-${base_name}-vnet/subnets/${subnet.name}']

module storage_accounts 'storage/blob.bicep' = [for layer in layers: {
  name: 'storage_account_${layer.name}'
  params: {
    containers: layer.containers
    account_name: 'ahtech${base_name_simple}${layer.abbr}'
    type: layer.type
    subnets: concat(layer.subnets, subnet_ids)
    ips: layer.ips
    rbac: layer.rbac
    enable_retention: layer.enable_retention
    enable_soft_delete: layer.enable_soft_delete
  }
  dependsOn: [
    vnet
  ]
  scope: rg
}]

var lz_ids = [for (layer, i) in layers: contains(layer.name, 'lz') ? i : 0]
var lz_id = max(lz_ids)

var db_accesspolicy = [
  {
    tenantId: subscription().tenantId
    objectId: '179735ea-7e6a-43f3-aa6f-4097ddc9687a' // AzureDatabricks
    permissions: {
      secrets: [
        'list'
        'set'
        'get'
      ]
    }
  }
]

var secrets_to_create = [
  {
    name: 'tenant-id'
    value: subscription().tenantId
  }
  {
    name: 'subscription-id'
    value: subscription().subscriptionId
  }
  {
    name: 'rg-name'
    value: rg.name
  }
  {
    name: 'appinsights-connectionstring'
    value: app_insights.outputs.appinsightsConnectionString
  }
  {
    name: 'dataexplorer-ingest-connectionstring'
    value: data_explorer_connection_string_ingest
  }
]

module keyvault 'keyvault/keyvault.bicep' = [for keyvault in keyvaults: {
  name: 'keyvault_${keyvault.name}'
  params: {
    keyvault_name: 'ahtech-${base_name}-kv${keyvault.abbr}'
    access_policies: concat(keyvault.access_policies, db_accesspolicy)
    subnets: concat(keyvault.subnets, subnet_ids)
    ips: keyvault.ips
    secrets: secrets_to_create
  }
  dependsOn: [
    vnet
  ]
  scope: rg
}]

module databricks 'databricks/databricks.bicep' = [for (databricks_workspace, i) in databricks_workspaces: {
  name: 'databricks-${databricks_workspace.name}'
  params: {
    workspace_name: 'ahtech-${base_name}-db-${databricks_workspace.abbr}'
    vnet: vnet.outputs.vnet_id
    private_subnet: subnets[i].name
    public_subnet: subnets[length(databricks_workspaces) + i].name
    la_workspace: log_analytics.outputs.la_id
    rbac: databricks_workspace.rbac
    data_producer_role: data_producer_role
    reader_role: reader_role
  }
  dependsOn: [
    vnet
  ]
  scope: rg
}]

output databricksWorkspaces array = [for (name, i) in databricks_workspaces: {
  abbr: name.abbr
  workspaceUrl: databricks[i].outputs.workspaceUrl
}]

output kusto_cluster string = data_explorer_connection_string_query


module eh_namespace 'eventhub/namespace.bicep' = if (length(eventhub.eventhubs) > 0) {
  name: 'eh_namespaces'
  params: {
    rbac: eventhub.rbac
    base_name: base_name
    lz_id: storage_accounts[lz_id].outputs.resource_id
    eventhubs: eventhub.eventhubs
    units: eventhub.units
    namespace_type: eventhub.type
  }
  dependsOn: [
    storage_accounts
  ]
  scope: rg
}
