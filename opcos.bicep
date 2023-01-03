// param opcos array
param opcos array
param env string

targetScope = 'subscription'

module dataplatform 'dataplatform.bicep' = [for opco in opcos: {
  name: '${env}-${opco.name}-dataplatform'
  params: {
    opco_name: opco.name
    layers: opco.layers
    eventhub: opco.eventhub
    keyvaults: opco.keyvaults
    env: env
    databricks_workspaces: opco.databricks_workspaces
    data_explorer: empty(opco.data_explorer) ? {} : opco.data_explorer
    data_producer_role: opco.data_producer_role
    data_quality_groups: opco.dq_mail_mapping
  }
}]

output databricksWorkspaces array = [for (opco, i) in opcos: {
  opco: opco.name
  databricks_workspaces: dataplatform[i].outputs.databricksWorkspaces
}]

output kusto_cluster_uri string = dataplatform[0].outputs.kusto_cluster
