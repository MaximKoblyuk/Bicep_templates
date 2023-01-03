param nsg_name string

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsg_name
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
        properties: {
          access: 'Allow'
          description: 'Required for worker nodes communication within a cluster.'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefixes: []
          destinationPortRange: '*'
          destinationPortRanges: []
          direction: 'Inbound'
          priority: 100
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-control-plane-to-worker-ssh'
        properties: {
          access: 'Allow'
          description: 'Required for Databricks control plane management of worker nodes.'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefixes: []
          destinationPortRange: '22'
          destinationPortRanges: []
          direction: 'Inbound'
          priority: 101
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureDatabricks'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: [] 
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-control-plane-to-worker-proxy'
        properties: {
          access: 'Allow'
          description: 'Required for Databricks control plane communication with worker nodes.'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefixes: []
          destinationPortRange: '5557'
          destinationPortRanges: []
          direction: 'Inbound'
          priority: 102
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureDatabricks'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp'
        properties: {
          access: 'Allow'
          description: 'Required for workers communication with Databricks Webapp.'
          destinationAddressPrefix: 'AzureDatabricks'
          destinationAddressPrefixes: []
          destinationPortRange: '443'
          destinationPortRanges: []
          direction: 'Outbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: []
        }
      } 
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
        properties: {
          access: 'Allow'
          description: 'Required for workers communication with Azure SQL services.'
          destinationAddressPrefix: 'Sql'
          destinationAddressPrefixes: []
          destinationPortRange: '3306'
          destinationPortRanges: []
          direction: 'Outbound'
          priority: 101
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
        properties: {
          access: 'Allow'
          description: 'Required for workers communication with Azure Storage services.'
          destinationAddressPrefix: 'Storage'
          destinationAddressPrefixes: []
          destinationPortRange: '443'
          destinationPortRanges: []
          direction: 'Outbound'
          priority: 102
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: []
        }
      }       
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
        properties: {
          access: 'Allow'
          description: 'Required for worker nodes communication within a cluster.'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefixes: []
          destinationPortRange: '*'
          destinationPortRanges: []
          direction: 'Outbound'
          priority: 103
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
        properties: {
          access: 'Allow'
          description: 'Required for worker communication with Azure Eventhub services.'
          destinationAddressPrefix: 'EventHub'
          destinationAddressPrefixes: []
          destinationPortRange: '9093'
          destinationPortRanges: []
          direction: 'Outbound'
          priority: 104
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourceAddressPrefixes: []
          sourcePortRange: '*'
          sourcePortRanges: []
        }
      }                                                 
    ]
  }
}

output nsg_id string = nsg.id
