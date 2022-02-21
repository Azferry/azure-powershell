#requires -version 2
<#
.SYNOPSIS
  Move subscriptions to the desired management group 
.DESCRIPTION
  From a CSV List of subscriptions move each one to the destination management group 
.PARAMETER DestinationManagementGroupId
  ID of the management group the subscriptions will be moved to 
.PARAMETER CSVPath
  Path to the CSV input file. CSV can be generatred with Pull-ReportOnMsdnSubs.ps1
.PARAMETER WhatIf
  True or False to allow the user to see what changes will be made in the environment 
.NOTES
  Required premissions: Owner on the child subscriptions, Owner/Contributor/MG Contributor
  on the target and destination management groups
.NOTES
  Version:        1.0
  Creation Date:  2/17/22
  Change: V1.0 - Initial script development
.NOTES
  LEGAL DISCLAIMER:
  This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree:
  (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
  (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
  (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code.
  This posting is provided "AS IS" with no warranties, and confers no rights.
.EXAMPLE
  Standard run of script 
  .\Move-SubsToManagementGroups.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -CSVPath "..\AzSubscriptions.csv" 
.EXAMPLE
  Run script with What if allows you to check what will happen before running
  .\Move-SubsToManagementGroups.ps1 -DestinationManagementGroupId "ntc-lz-sbx" -CSVPath "..\AzSubscriptions.csv"  -WhatIf $true
#>


Param (
[Parameter(Mandatory=$true)][string]$DestinationManagementGroupId,
[Parameter(Mandatory=$true)][string]$CSVPath,
[Parameter(Mandatory=$false)][bool]$WhatIf = $false
)


# Connect-AzAccount 
# $DestinationManagementGroupId = "MyGroup"

try {
  $SubList = Import-CSV -Path ..\AzSubscriptions.csv
  Write-Host "CSV Imported" -ForegroundColor Green
  Write-Host ((($SubList).Count).ToString() + " Subscriptions are going to be moved") 

  Write-Host -nonewline "Do you want to continue with the move? (Y/N) "
  $response = Read-Host
  if (($response -ne "Y") -or ($response -ne "y")) { 
    Write-Host "Exit"
    exit 
  }

  ## Check if MG Group Exists
  if(!get-azmanagementgroup -GroupId $DestinationManagementGroupId ){
    Write-Host "HI"
  }

  foreach ($sub in $SubList){
    if($WhatIf){
      New-AzManagementGroupSubscription -GroupId $DestinationManagementGroupId -SubscriptionId $sub.SubscriptionId -WhatIf
      Write-Host ("WhatIf - Move Sub: " + $sub.Name + " to Management group:  $DestinationManagementGroupId") -ForegroundColor Yellow
    }
    else {
      New-AzManagementGroupSubscription -GroupId $DestinationManagementGroupId -SubscriptionId $sub.SubscriptionId 
      Write-Host ("Move Sub: " + $sub.Name + " to Management group:  $DestinationManagementGroupId") -ForegroundColor Green
    }
  }
 
}
catch {
  Write-Host "Error running the script, Check premissions and input" -ForegroundColor Red
}
finally {
  Write-Host "Script complete" -ForegroundColor Green
}