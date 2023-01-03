param container_name string
param account_name string
param rbac array


resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${account_name}/default/${container_name}'
}

module role_assignments 'container_rbac.bicep' = if (length(rbac) > 0) {
  name: '${container_name}-rbac'
  params: {
    rbac: rbac
    resource_name: container.name
  }
}
