#requires -version 2
<#
.SYNOPSIS
  Create a new subscription with in an EA Agreement
.DESCRIPTION
  Creating new subscriptions from within an EA Agreement, and moving them to the 
  management group after creation.
.PARAMETER BillingScope
  Scope of billing within the EA portal
  Ex: "/providers/Microsoft.Billing/BillingAccounts/1234567/enrollmentAccounts/7654321"
.PARAMETER WorkloadType
  Type of subscription (DevTest or Production)
.PARAMETER SubAlias
  Subscription  Alias for the new subscription (can be the same as name)
.PARAMETER SubscriptionName
  Name of the new subscription 
.PARAMETER DestinationManagementGroupId
  The ID Of the management group the subscription should be placed in
.COMPONENT 
  Requires Module Az.Subscription
.LINK 
  https://github.com/Azferry/azure-powershell
.NOTES
  Version:        1.0
  Creation Date:  2/18/22
  Change: V1.0 - Initial script development
.EXAMPLE
  Create a Production Subscription 
  .\New-AzureEaSubscription.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -SubscriptionName "Name" -SubAlias "Name" -BillingScope "/providers/Microsoft.Billing/BillingAccounts/1234567/enrollmentAccounts/7654321"
.EXAMPLE
  Create a DevTest Subscription 
  .\New-AzureEaSubscription.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -SubscriptionName "Name" -SubAlias "Name" -BillingScope "/providers/Microsoft.Billing/BillingAccounts/1234567/enrollmentAccounts/7654321" -WorkloadType "DevTest"
#>


Param (
  [Parameter(Mandatory=$true)][string]$SubAlias,
  [Parameter(Mandatory=$true)][string]$SubscriptionName,
  [Parameter(Mandatory=$true)][string]$DestinationManagementGroupId,
  [Parameter(Mandatory=$true)][string]$BillingScope,
  [Parameter(Mandatory=$false)][string]$WorkloadType = "Production"
)

Connect-AzAccount 


if (Get-Module -ListAvailable -Name "Az.Subscription") {
  Write-Host "Module Already installed on the system"
}
else {
  Write-Host "Module does not exist - installing module"
  Install-Module Az.Subscription
}
Import-Module Az.Subscription


$EaSub = New-AzSubscriptionAlias -AliasName $SubAlias `
      -SubscriptionName $SubscriptionName `
      -BillingScope $BillingScope `
      -Workload $WorkloadType

Write-Host "New Subscription Created" -ForegroundColor Green

New-AzManagementGroupSubscription -GroupId $DestinationManagementGroupId -SubscriptionId $EaSub.Id  
Write-Host ("Move Sub: " + $EaSub.Id  + " to Management group:  $DestinationManagementGroupId") -ForegroundColor Green