param base_name string
param eventhubs array
param lz_id string
param rbac array
param units int
param namespace_type string

resource namespace 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: 'ahtech${base_name}eh01'
  location: resourceGroup().location
  sku: {
    name: namespace_type
    tier: namespace_type
    capacity: units
  }
  properties: {
    isAutoInflateEnabled: false
    kafkaEnabled: true
    zoneRedundant: true
  }
}

resource role_assignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for role in rbac: {
  name: guid(role.objectId, role.role, namespace.name, resourceGroup().name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role.role)
    principalId: role.objectId
  }
  scope: namespace
}]

resource auth_rules 'Microsoft.EventHub/namespaces/authorizationRules@2021-01-01-preview' = {
  name: 'kafka-reader'
  properties: {
    rights: [
      'Listen'
    ]
  }
  parent: namespace
}

module eventhub 'eventhub.bicep' = [for eventhub in eventhubs: if (eventhub.create_eh) {
  name: '${eventhub.source_system}-${eventhub.feed}'
  params: {
    capture: eventhub.capture
    feed: eventhub.feed
    rbac: eventhub.rbac
    retention: eventhub.retention
    namespace_name: namespace.name
    lz_id: lz_id
    source_system: eventhub.source_system
  }
}]
