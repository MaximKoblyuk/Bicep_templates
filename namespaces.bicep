param eventhub_namespaces array
param base_name string
param lz_id string

module namespace 'namespace.bicep' = [for eh_namespace in eventhub_namespaces: {
  name: 'eh-${eh_namespace.name}'
  params: {
    namespace_name: 'ahtech${base_name}eh${eh_namespace.name}'
    eventhubs: eh_namespace.eventhubs
    lz_id: lz_id
  }
}]
