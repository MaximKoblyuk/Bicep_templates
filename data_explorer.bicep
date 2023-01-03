param data_explorer_name string
param configuration object
param forceUpdateTag string = utcNow()
param la_workspace string

resource data_explorer 'Microsoft.Kusto/clusters@2022-02-01' = {
  name: data_explorer_name
  location: resourceGroup().location

  identity: {
    type: 'SystemAssigned'
  }
  sku: configuration.sku
  properties: configuration.properties
}

resource diagSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  scope: data_explorer
  name: 'service'
  properties: {
    workspaceId: la_workspace
    logs: [
      {
        category: 'FailedIngestion'
        enabled: true
      }
    ]
  }
}

resource thor_metrics 'Microsoft.Kusto/clusters/databases@2022-02-01' = {
  name: 'thor-cf2-metrics'
  location: resourceGroup().location
  kind: 'ReadWrite'
  parent: data_explorer

  resource database_role_assignments 'principalAssignments' = [for role in configuration.database_roles: {
    name: role.name
    properties: {
      principalId: role.principal_id
      principalType: role.principal_type
      role: role.role
    }
  }]
}

resource dqf_metrics 'Microsoft.Kusto/clusters/databases@2022-02-01' = {
  name: 'dqf-cf2-metrics'
  location: resourceGroup().location
  kind: 'ReadWrite'
  parent: data_explorer

  resource database_role_assignments 'principalAssignments' = [for role in configuration.database_roles: {
    name: role.name
    properties: {
      principalId: role.principal_id
      principalType: role.principal_type
      role: role.role
    }
  }]
}

resource setup_tables 'Microsoft.Kusto/clusters/databases/scripts@2022-02-01' = {
  name: 'setup_tables'
  parent: thor_metrics
  properties: {
    scriptContent: loadTextContent('data_explorer_setup_tables.kql')
    continueOnErrors: false
    forceUpdateTag: forceUpdateTag
  }
}

resource setup_mappings 'Microsoft.Kusto/clusters/databases/scripts@2022-02-01' = {
  name: 'setup_mappings'
  parent: thor_metrics
  properties: {
    scriptContent: loadTextContent('data_explorer_setup_mappings.kql')
    continueOnErrors: false
    forceUpdateTag: forceUpdateTag
  }
  dependsOn: [ setup_tables ]
}

resource setup_dqf_tables 'Microsoft.Kusto/clusters/databases/scripts@2022-02-01' = {
  name: 'setup_dqf_tables'
  parent: dqf_metrics
  properties: {
    scriptContent: loadTextContent('data_explorer_setup_dqf_tables.kql')
    continueOnErrors: false
    forceUpdateTag: forceUpdateTag
  }
  dependsOn: [ setup_mappings ]
}

resource setup_dqf_mappings 'Microsoft.Kusto/clusters/databases/scripts@2022-02-01' = {
  name: 'setup_dqf_mappings'
  parent: dqf_metrics
  properties: {
    scriptContent: loadTextContent('data_explorer_setup_dqf_mappings.kql')
    continueOnErrors: false
    forceUpdateTag: forceUpdateTag
  }
  dependsOn: [ setup_dqf_tables ]
}

resource role_assignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for role in configuration.rbac: {
  name: guid(role.objectId, role.role, data_explorer.name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role.role)
    principalId: role.objectId
  }
  scope: data_explorer
}]

resource cluster_role_assignments 'Microsoft.Kusto/clusters/principalAssignments@2022-02-01' = [for role in configuration.cluster_roles: {
  name: role.name
  parent: data_explorer
  properties: {
    principalId: role.principal_id
    principalType: role.principal_type
    role: role.role
  }
}]

output dataexplorer_ingest_connectionstring string = data_explorer.properties.dataIngestionUri
output dataexplorer_uri string = data_explorer.properties.uri
