param workspace_name string
param vnet string
param public_subnet string
param private_subnet string
param la_workspace string
param rbac array
param data_producer_role object
param reader_role string

resource databricks 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: workspace_name
  location: resourceGroup().location
  properties: {
    managedResourceGroupId: '${subscription().id}/resourceGroups/databricks-rg-${workspace_name}'
    parameters: {
      customVirtualNetworkId: {
        value: vnet
      }
      customPublicSubnetName: {
        value: public_subnet
      }
      customPrivateSubnetName: {
        value: private_subnet
      }
    }
  }
}

resource diagSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  scope: databricks
  name: 'service'
  properties: {
    workspaceId: la_workspace
    logs: [
      {
        category: 'dbfs'
        enabled: true
      }
      {
        category: 'jobs'
        enabled: true
      }
    ]
  }
}

resource role_assignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for role in rbac: {
  name: guid(role.objectId, role.role, resourceGroup().name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role.role)
    principalId: role.objectId
  }
  scope: databricks
}]

resource dataproducer_reader_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(data_producer_role.object_id, databricks.name, reader_role, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', reader_role)
    principalId: data_producer_role.object_id
  }
  scope: databricks
}

output workspaceUrl string = databricks.properties.workspaceUrl
