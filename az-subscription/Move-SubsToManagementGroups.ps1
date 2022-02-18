#requires -version 2
<#
.SYNOPSIS
  Move subscriptions to the desired management group 
.DESCRIPTION
  From a CSV List of subscriptions move each one to the destination management group 
.PARAMETER DestinationManagementGroupName
  Name of the management group the subscriptions will be moved to 
.PARAMETER CSVPath
  Path to the CSV input file
.PARAMETER WhatIf
  True or False to allow the user to see what changes will be made in the environment 
.NOTES
  Required premissions: Owner on the child subscriptions, Owner/Contributor/MG Contributor
  on the target and destination management groups
.NOTES
  Version:        1.0
  Creation Date:  2/17/22
  Purpose/Change: Initial script development
.EXAMPLE
  .\Move-SubsToManagementGroups.ps1 -DestinationManagementGroupName "ntc-lz-sbx" -CSVPath "..\AzSubscriptions.csv" 
  .\Move-SubsToManagementGroups.ps1 -DestinationManagementGroupName "ntc-lz-sbx" -CSVPath "..\AzSubscriptions.csv"  -WhatIf $true
#>


Param (
[Parameter(Mandatory=$true)][string]$DestinationManagementGroupName,
[Parameter(Mandatory=$true)][string]$CSVPath,
[Parameter(Mandatory=$false)][bool]$WhatIf = $false
)

# Connect-AzAccount

try {
  $SubList = Import-CSV -Path ..\AzSubscriptions.csv
  Write-Host "CSV Imported" -ForegroundColor Green
  Write-Host ((($SubList).Count).ToString() + " Subscriptions are going to be moved") 
  Write-Warning "Move subscriptin List to management group?" -WarningAction Inquire

  foreach ($sub in $SubList){
    if($WhatIf){
      New-AzManagementGroupSubscription -GroupName $DestinationManagementGroupName -SubscriptionId $sub.SubscriptionId -WhatIf
    }
    else {
      New-AzManagementGroupSubscription -GroupName $DestinationManagementGroupName -SubscriptionId $sub.SubscriptionId 
      Write-Host ("Move Sub: " + $sub.Name + " to Management group:  $DestinationManagementGroupName") -ForegroundColor Green
    }
  }
 
}
catch {
  Write-Host "Error" -ForegroundColor Red
}
finally {
  Write-Host "Script complete" -ForegroundColor Green
}