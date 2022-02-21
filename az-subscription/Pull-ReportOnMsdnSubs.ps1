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
  Version:        1.0
  Creation Date:  2/15/22
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>


# Connect-AzAccount -Environment AzureCloud -Tenant "3ce2effc-ffcd-47fc-b417-e687def644b5"
$CSV_FileName = "AzSubscriptions.csv"

$MgList = Get-AzManagementGroup
$MgSubList = @()

foreach($m in $MgList){
  $tenantRootSubscriptions = ((Get-AzManagementGroup -GroupId $m.Name -Expand -Recurse).Children | Where-Object {$_.Type -match 'subscriptions'}) | Select-Object -Property Name, DisplayName, Id
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
$SubList = (Get-AzSubscription | Select-Object * | ? {$_.SubscriptionPolicies.QuotaId -like "MSDN*"}) | Select-Object Name, State, SubscriptionId, TenantId, HomeTenantId, SubscriptionPolicies

foreach($sub in $SubList){
  $Mg = $MgSubList | Where-Object -FilterScript {$_.SubscriptionId -EQ $sub.SubscriptionId}
  $Policies = $sub.SubscriptionPolicies | ConvertFrom-Json 

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
  }
  $SubReportList += $S
}

$SubReportList | Export-Csv -Path .\$CSV_FileName -NoTypeInformation
