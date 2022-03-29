# Azure Powershell Scripts

Collection of scripts for Azure

## Powershell Scripts

| Item                            | Description                                                                                   | File In Repository                                     |
| ------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| Pull-ReportOnMsdnSubs.ps1       | Pulls a list of MSDN subscriptions in the tenant and exports them to a CSV                    | [Script](/az-subscription/Pull-ReportOnMsdnSubs.ps1)   |
| Move-SubsToManagementGroups.ps1 | Move subscriptions to a management group from a CSV input                                     | [Script](/az-subscription/Pull-ReportOnMsdnSubs.ps1)   |
| New-AzureEaSubscription.ps1     | Creates a new subscription in an EA Agreement                                                 | [Script](/az-subscription/New-AzureEaSubscription.ps1) |
| Get-BillingAccountsEA.ps1       | Get all the billing scopes a the authenticated user has access to.                            | [Script](/az-subscription/Get-BillingAccountsEA.ps1)   |
| Get-ReportPublicIps.ps1         | Loops through all subscriptions under a management group, to pulls a report on all public ips | [Script](/az-publicIp/Get-ReportPublicIps.ps1)         |
| Delete-PublicIPs.ps1            | :warning: Delete all public Ips provided in Get-ReportPublicIPs.ps1                           | [Script](/az-publicIp/Delete-PublicIPs.ps1)            |

## Azure Automation Runbooks

### Runbooks

| Item | Description | File In Repository |
| ---- | ----------- | ------------------ |

### Example Powershell

| Item | Description | File In Repository |
| ---- | ----------- | ------------------ |
|runbook-csvimport.ps1 | Shows how to upload and download csv files from storage account | [Script](/az-aa-runbooks/examples/runbook-csvimport.ps1) |
