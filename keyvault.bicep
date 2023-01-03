param keyvault_name string
param subnets array
param ips array
param access_policies array
param secrets array

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyvault_name
  location: resourceGroup().location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 30
    publicNetworkAccess: 'enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [for subnet_id in subnets: {
        id: subnet_id
      }]
      ipRules: [for ip_rule in ips: {
        value: ip_rule
      }]
    }
    accessPolicies: access_policies
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2020-04-01-preview' = [for secret in secrets:{
  name: secret.name
  parent: keyvault
  properties: {
    value: secret.value
  }
}]
