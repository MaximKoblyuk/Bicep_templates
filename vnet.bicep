param vnet_name string
param subnets array
param nsg_id string

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnet_name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/12'
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.properties.addressPrefix
        networkSecurityGroup: {
          id: nsg_id
        }
        serviceEndpoints: subnet.properties.serviceEndpoints
        delegations: [
          {
            name: 'DatabricksDelegation'
            properties: {
              serviceName: 'Microsoft.Databricks/workspaces'
            }
          }
        ]
      }
    }]
  }
}

output vnet_id string = vnet.id
