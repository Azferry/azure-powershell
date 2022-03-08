#requires -version 2
<#
.SYNOPSIS
  Pull a report of all public Ips attached to Nics 
.DESCRIPTION
  Pulls a report of all the network interfaces that have a public ip attached. 
.PARAMETER ManagementGroup
  Name of the management group to pull the list of subscriptions from. When using the management group flag dont add the subscription parameter. 
.PARAMETER SubscriptionId
  ID of the subscription to pull the list of public ips from. When using the Subscription flag dont add the management group parameter. 
.PARAMETER OnlyAttachedPip
  Flag that sets the filter to only pull public IPs that are attached to network interfaces - $true or $false
.PARAMETER OnlyDetachedPip
  Flag that sets the filter to only pull detached public IPs - $true or $false 
.INPUTS
  None
.NOTES
  Version:        1.1
  Creation Date:  2/25/22
  Change: V1.0 - Initial script development
          V1.1 - Cleanup and fix csv export access issue
.COMPONENT 
  Requires Module Az.Network
.LINK 
  https://github.com/Azferry/azure-powershell
.EXAMPLE
  Pull All Public IPs 
  .\Get-ReportPublicIps.ps1 -ManagementGroup "ntc-lz-npd"
.EXAMPLE
  Pull only detached Public IPs 
  .\Get-ReportPublicIps.ps1 -ManagementGroup "ntc-lz-npd" -OnlyDetachedPip $true
.EXAMPLE
  Pull only attached Public IPs 
  .\Get-ReportPublicIps.ps1 -ManagementGroup "ntc-lz-npd" -OnlyAttachedPip $true
.EXAMPLE
  Pull only one subscription  
  .\Get-ReportPublicIps.ps1 SubscriptionId "16632089-aa31-498a-8b82-39b0405c4c55"
#>


Param (
  [Parameter(Mandatory=$false)][string]$ManagementGroup,
  [Parameter(Mandatory=$false)][string]$SubscriptionId,
  [Parameter(Mandatory=$false)][bool]$OnlyAttachedPip = $false ,
  [Parameter(Mandatory=$false)][bool]$OnlyDetachedPip = $false
)

if (Get-Module -ListAvailable -Name "Az.Network") {
  Write-Host "Module Already installed on the system"
}
else {
  Write-Host "Module does not exist - installing module"
  Install-Module Az.Network
}
Import-Module Az.Network

# Connect-AzAccount


$CSV_FileName = ".\PublicIpReport.csv"

$SubscriptionList = @()
if($ManagementGroup){
  write-host "Get all subscriptions under a Management Group"
  $MG = Get-AzManagementGroup -GroupName $ManagementGroup -Expand -Recurse
  $SubscriptionList = $MG.Children | Where-Object  -FilterScript {$_.Type -eq "/subscriptions"}
}elseif ($SubscriptionId) {
  write-host "Subscription"
  $SubscriptionList += $SubscriptionId
}
write-host ("Total Subscriptions = " + $SubscriptionList.Count )
$PublicIpList = @()

foreach($Subscription in $SubscriptionList){
  Write-Host ("AZ Context: " + $Subscription.DisplayName)
  Set-AzContext -Subscription $Subscription.DisplayName
  if($OnlyAttachedPip){
    $Piplist = Get-AzPublicIpAddress | Where-Object -FilterScript {$_.IpConfiguration -ne $null}
  }elseif($OnlyDetachedPip){
    $Piplist = Get-AzPublicIpAddress | Where-Object -FilterScript {$_.IpConfiguration -eq $null}
  }else{
    $Piplist = Get-AzPublicIpAddress
  }
  
  foreach($Ip in $Piplist){
    # $Ip
    $IPConfig = $Ip[0].IpConfiguration.id
    if($null -ne $IPConfig){
      $IPConfig
      if($IPConfig.Split("/")[7] -ne "loadBalancers"){ 
        $NetworkInterfaceName = $IPConfig.Split("/")[8]
        $NetworkInterfaceRG = $IPConfig.Split("/")[4]
        $Nic = Get-AzNetworkInterface -Name $NetworkInterfaceName -ResourceGroupName $NetworkInterfaceRG
        $VmId = $Nic[0].VirtualMachine.id
        $VmName = $VmId.Split("/")[8]
      }
    }
    else {
      $Nic = $null
      $VmId = $null
      $VmName = $null
    }
    
    $PIPObject = [PSCustomObject]@{
      PipName = $Ip.Name
      VmName = $VmName
      SubscriptionName = $Subscription.DisplayName
      ResourceGroupName = $Ip.ResourceGroupName
      PublicIpAllocationMethod = $Ip.PublicIpAllocationMethod
      IpAddress = $Ip.IpAddress
      PublicIpAddressVersion = $Ip.PublicIpAddressVersion
      IpConfiguration = $Ip.IpConfiguration.Id
      PipId = $Ip.Id
      NicId = $Nic.Id
      VmId = $VmId
    }
    $PIPObject
    $PublicIpList += $PIPObject
  }
}

$PublicIpList | Export-Csv -Path $CSV_FileName -NoTypeInformation
