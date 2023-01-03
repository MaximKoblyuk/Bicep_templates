param account_name string
param containers array
param type string
param subnets array
param ips array
param rbac array
param enable_retention bool
param enable_soft_delete bool

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: account_name
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  location: resourceGroup().location
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [for subnet in subnets: {
        id: subnet
      }]
      defaultAction: 'Deny'
      ipRules: [for ip_rule in ips: {
        value: ip_rule
      }]
    }
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: type == 'adls' ? true : false
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
  }
}

resource storage_account_properties 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storage
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 30
      enabled: true
    }
  }
}


resource management_policies 'Microsoft.Storage/storageAccounts/managementPolicies@2021-04-01' = if (enable_retention) {
  parent: storage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'delete-after-28-days'
          enabled: length(containers) > 0
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: 28
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
                'appendBlob'
              ]
            }
          }
        }
      ]
    }
  }
}

module role_assignments 'storage_account_rbac.bicep' = if (length(rbac) > 0) {
  name: '${storage.name}-rbac'
  params: {
    rbac: rbac
    resource_name: storage.name
  }
}

module containers_module 'containers.bicep' = if (length(containers) > 0) {
  name: '${account_name}-containers'
  params: {
    account_name: storage.name
    containers: containers
  }
}

output resource_id string = storage.id
output resource_url string = storage.properties.primaryEndpoints.blob
