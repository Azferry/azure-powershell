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
.PARAMETER UserUPN 
  Optional - The full user principle name of the aad user for the role assignment to subscription
.PARAMETER RoleNmae
  Optional - name of the role to give to the user defined in the UPN
.COMPONENT 
  Requires Module Az.Subscription
.LINK 
  https://github.com/Azferry/azure-powershell
.NOTES
  Version:        1.2
  Creation Date:  2/18/22
  Change: V1.0 - Initial script development
          V1.1 - Mv subscription to mg group
          v1.2 - Add role assignments and user
.NOTES
  There's a limit of 5000 subscriptions per enrollment account. After that, more subscriptions for the account can only be
  created in the Azure portal. To create more subscriptions through the API, create another enrollment account. Canceled,
  deleted, and transferred subscriptions count toward the 5000 limit.
.EXAMPLE
  Create a Production Subscription 
  .\New-AzureEaSubscription.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -SubscriptionName "Name" -SubAlias "Name" -BillingScope "/providers/Microsoft.Billing/BillingAccounts/1234567/enrollmentAccounts/7654321"
.EXAMPLE
  Create a DevTest Subscription 
  .\New-AzureEaSubscription.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -SubscriptionName "Name" -SubAlias "Name" -BillingScope "/providers/Microsoft.Billing/BillingAccounts/1234567/enrollmentAccounts/7654321" -WorkloadType "DevTest"
.EXAMPLE
  Create a production subscription and add the user to the owner role
  .\New-AzureEaSubscription.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -SubscriptionName "Name" -SubAlias "Name" -BillingScope "/providers/Microsoft.Billing/BillingAccounts/1234567/enrollmentAccounts/7654321" -UserUPN "user@consto.com"
.EXAMPLE
  Create a production subscription and add the reader role to a user
  .\New-AzureEaSubscription.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -SubscriptionName "Name" -SubAlias "Name" -BillingScope "/providers/Microsoft.Billing/BillingAccounts/1234567/enrollmentAccounts/7654321" -UserUPN "user@consto.com" -RoleName "Reader"
#>


Param (
  [Parameter(Mandatory=$true)][string]$SubAlias,
  [Parameter(Mandatory=$true)][string]$SubscriptionName,
  [Parameter(Mandatory=$true)][string]$DestinationManagementGroupId,
  [Parameter(Mandatory=$true)][string]$BillingScope,
  [Parameter(Mandatory=$false)][string]$UserUPN,
  [Parameter(Mandatory=$false)][string]$WorkloadType = "Production",
  [Parameter(Mandatory=$false)][string]$RoleName = "Owner"
)

Connect-AzAccount 

## Module import / install
if (Get-Module -ListAvailable -Name "Az.Subscription") {
  Write-Host "Module Already installed on the system"
}
else {
  Write-Host "Module does not exist - installing module"
  Install-Module Az.Subscription
}
Import-Module Az.Subscription

## Create the subscription within the EA Agreement
## https://docs.microsoft.com/en-us/powershell/module/az.subscription/new-azsubscriptionalias?view=azps-7.2.0
$EaSub = New-AzSubscriptionAlias -AliasName $SubAlias `
      -SubscriptionName $SubscriptionName `
      -BillingScope $BillingScope `
      -Workload $WorkloadType

Write-Host "New Subscription Created" -ForegroundColor Green
Write-Host "Waiting for subscription to show up" -ForegroundColor Green
## Wait for sub to be show in portal 
Start-Sleep -s 20

## Move the subscription to a management group
$NewSubscription = Get-AzSubscription -subscriptionname $SubscriptionName | Select-Object *
New-AzManagementGroupSubscription -GroupId $DestinationManagementGroupId -SubscriptionId $NewSubscription.Id  
Write-Host ("Move Sub: " + $NewSubscription.Id  + " to Management group: $DestinationManagementGroupId") -ForegroundColor Green

## Will show an error if the role assignment already exisits
if ($UserUPN) {
    $Scope = "/subscriptions/" + $NewSubscription.Id 
    $ObjID = (Get-AzADUser -UserPrincipalName $UserUPN).Id
    # (Get-AzADGroup -DisplayName <groupName>).id
    New-AzRoleAssignment -ObjectId $ObjID `
            -RoleDefinitionName $RoleName `
            -Scope $Scope
}