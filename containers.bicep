param containers array
param account_name string


module container 'container.bicep' = [for container in containers: {
  name: guid('${account_name}-${container.name}')
  params: {
    container_name: container.name
    account_name: account_name
    rbac: container.rbac
  }
}]
