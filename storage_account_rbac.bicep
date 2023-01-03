param rbac array
param resource_name string

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: resource_name
}

resource assignmentResource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for rbac_entry in rbac: {
  name: guid(rbac_entry.objectId, rbac_entry.role, resource_name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbac_entry.role)
    principalId: rbac_entry.objectId
  }
  scope: storage
}]
