param opcoName string
param environment string
param actionGroupsArray array

resource actionGroups 'microsoft.insights/actionGroups@2022-04-01' = [for i in range(0, length(actionGroupsArray)): {
  name: '${opcoName}_${environment}_${actionGroupsArray[i].assignment_group}_AG'
  location: 'Global'
  properties: {
    groupShortName: '${take(toLower(actionGroupsArray[i].assignment_group), 10)}AG'
    enabled: true
    emailReceivers: [
      {
        name: actionGroupsArray[i].assignment_group
        emailAddress: actionGroupsArray[i].email
        useCommonAlertSchema: true
      }
    ]
    smsReceivers: []
    webhookReceivers: []
    eventHubReceivers: []
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: []
  }
}]
