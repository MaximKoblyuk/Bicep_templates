param logAnalyticsId string
param opcoName string
param environment string
param dqGroups array


resource scheduledqueryrules_L2_bla_notification_name_resource 'microsoft.insights/scheduledqueryrules@2021-08-01' = [for i in range(0, length(dqGroups)): {
  name: '${opcoName}_${environment}_${dqGroups[i].assignment_group}_Alert' 
  location: resourceGroup().location
  properties: {
    displayName: 'Data Quality Alert ${opcoName} ${environment} ${dqGroups[i].assignment_group}' 
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsId
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AppTraces\r\n| extend Properties = parse_json(Properties)\r\n| extend BusinessObjectName = tostring(Properties.business_object_name)\r\n| extend AssignmentGroup = tostring(Properties.assignment_group)\r\n| extend Priority = toint(Properties.priority)\r\n| extend Result = tobool(Properties.validation_successful)\r\n| extend Description = tostring(Properties.validation_description)\r\n| extend TimeStamp = tostring(Properties.timestamp)\r\n| extend NotenbookUrl = tostring(Properties.notebook_url)\r\n| where Result == False\r\n| where AssignmentGroup == "${dqGroups[i].assignment_Group}"\r\n| order by BusinessObjectName asc, Priority asc\r\n| project BusinessObjectName, Priority, TimeStamp, AssignmentGroup, Description, NotenbookUrl'
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [
        '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/microsoft.insights/actionGroups/${opcoName}_${environment}_${dqGroups[i].assignment_group}_AG'
      ]
    }
  }
}]
