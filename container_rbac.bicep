param rbac array
param resource_name string

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' existing = {
  name: resource_name
}

resource assignmentResource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for rbac_entry in rbac: {
  name: guid(rbac_entry.objectId, rbac_entry.role, resource_name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbac_entry.role)
    principalId: rbac_entry.objectId
  }
  scope: container
}]
