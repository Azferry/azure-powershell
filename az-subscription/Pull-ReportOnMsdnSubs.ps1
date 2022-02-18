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


Connect-AzAccount -Environment AzureCloud
$CSV_FileName = "MsdnSubscriptions.csv"

$tenantId = (Get-AzContext).Tenant.Id

$SubList = Get-AzSubscription | select * | ? {$_.SubscriptionPolicies.QuotaId -like "MSDN*"}

$MsdnSubs = $SubList | Select Name, State, SubscriptionId, TenantId,HomeTenantId, SubscriptionPolicies

$MsdnSubs | Export-Csv -Path .\$CSV_FileName -NoTypeInformation
