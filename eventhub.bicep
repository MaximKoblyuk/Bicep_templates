param namespace_name string
param source_system string
param feed string
param rbac array
param capture bool
param lz_id string
param retention int

resource eventhub 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = {
  name: '${namespace_name}/${source_system}-${feed}'
  properties: {
    messageRetentionInDays: retention
    partitionCount: 1
    captureDescription: {
      enabled: capture
      skipEmptyArchives: true
      encoding: 'Avro'
      intervalInSeconds: 300
      sizeLimitInBytes: 300 * 1024 * 1024
      destination: {
        name: 'EventHubArchive.AzureBlockBlob'
        properties: {
          storageAccountResourceId: lz_id
          blobContainer: '${source_system}-${feed}'
          archiveNameFormat: '{Namespace}/{EventHub}/{Year}/{Month}/{Day}/{PartitionId}/{Hour}/{Minute}/{Second}'
        }
      }
    }
  }
}

resource assignmentResource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for rbac_entry in rbac: {
  name: guid(rbac_entry.objectId, rbac_entry.role, eventhub.name, subscription().id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbac_entry.role)
    principalId: rbac_entry.objectId
  }
  scope: eventhub
}]

resource auth_rules_sender 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  name: '${source_system}-${feed}-sender'
  properties: {
    rights: [
      'Send'
    ]
  }
  parent: eventhub
}

resource auth_rules 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  name: '${source_system}-${feed}-reader'
  properties: {
    rights: [
      'Listen'
    ]
  }
  parent: eventhub
}
