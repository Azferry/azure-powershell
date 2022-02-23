#requires -version 2
<#
.SYNOPSIS
  Pull a list of azure MSDN subscriptions within the tenant
.DESCRIPTION
  Generates a report CSV with the list of MSDN subscriptions in the tenant. MSDN have a QuotaId of "MSDN*"
  And typically has a spendinglimit enabled 
.PARAMETER CSV_FileName
  CSV File name for the export
.OUTPUTS
  Stores the CSV to the current running directory
.NOTES
  Version:        1.1
  Creation Date:  2/15/22
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\Pull-ReportOnMsdnSubs.ps1
#>


Connect-AzAccount -Environment AzureCloud
$CSV_FileName = "AzSubscriptions.csv"
$AzTenant = (Get-AzContext).Tenant.Id
$MgList = Get-AzManagementGroup
$MgSubList = @()
$SubQuoteID = "MSDN*"
$RoleID = "8e3af657-a8ff-443c-a75c-2fe8c4bcb635" ## Owner Role - Standard accross tenants 

foreach($m in $MgList){
  $tenantRootSubscriptions = ((Get-AzManagementGroup -GroupId $m.Name -Expand -Recurse).Children | `
      Where-Object {$_.Type -match 'subscriptions'}) | `
      Select-Object -Property Name, DisplayName, Id

  foreach($i in $tenantRootSubscriptions) {
    $SubObject = [PSCustomObject]@{
      ManagementGroup = $m.DisplayName
      ManagementGroupId = $m.Id
      SubscriptionId = $i.Name
      SubscriptionDisplayName = $i.DisplayName
      }
    $MgSubList += $SubObject
  }
}

$SubReportList = @()
    
$SubList = (Get-AzSubscription -TenantId $AzTenant | Select-Object * | `
    ? {$_.SubscriptionPolicies.QuotaId -like $SubQuoteID}) | `
    Select-Object Name, State, SubscriptionId, TenantId, HomeTenantId, SubscriptionPolicies

foreach($sub in $SubList){
  $Mg = $MgSubList | Where-Object -FilterScript {$_.SubscriptionId -EQ $sub.SubscriptionId}
  $Policies = $sub.SubscriptionPolicies | ConvertFrom-Json 
  $SubscriptionScope = "/subscriptions/" + $sub.SubscriptionId

  $SubscriptionRbacAssignment = Get-AzRoleAssignment -RoleDefinitionId $RoleID -Scope $SubscriptionScope | `
        Where-Object {($_.ObjectType -EQ "user") -and ($_.Scope -EQ $SubscriptionScope) } | `
        Select-Object DisplayName, SignInName, RoleDefinitionName | `
        ConvertTo-Json

  $S = [PSCustomObject]@{
    Name = $sub.Name
    State = $sub.State
    SubscriptionId = $sub.SubscriptionId
    TenantId = $sub.TenantId
    HomeTenantId = $sub.HomeTenantId
    QuoteID = $Policies.QuotaId
    SpendingLimit = $Policies.SpendingLimit
    ManagementGroup = $Mg.ManagementGroup
    ManagementGroupId = $Mg.ManagementGroupId
    SubscriptionOwners = $SubscriptionRbacAssignment
  }
  $SubReportList += $S
}

$SubReportList | Export-Csv -Path .\$CSV_FileName -NoTypeInformation
