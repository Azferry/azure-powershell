#requires -version 2
<#
.SYNOPSIS
  Shows how to use storage accounts to hold csv files for automation accounts
.DESCRIPTION
  Gets a list of virtual machines in azure and uploads it as a csv. Once uploaded the script downloads the csv report and 
  reimports the csv file.
.PARAMETER connectionName
  Name of the connection to azure within the automation account
.PARAMETER storageAccountName
  Name of the storage account
.PARAMETER storageAccountKey
  SAS key for the storage account auth
.PARAMETER containerName
  Container name the file will be stored within the storage account
.PARAMETER vmReportName
  Name of the VM report file
.NOTES
  Version:        1.0
  Creation Date:  3/29/22
  Change: V1.0 - Initial script development
.COMPONENT 
  Requires Module Az.Storage, Az.Compute
.LINK 
  https://github.com/Azferry/azure-powershell
#>

Import-Module Az.Compute
Import-Module Az.Storage

$connectionName = "AzureRunAsConnection"
try {
	$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
	"Logging in to Azure..."
	Add-AzAccount `
		-ServicePrincipal `
		-TenantId $servicePrincipalConnection.TenantId `
		-ApplicationId $servicePrincipalConnection.ApplicationId `
		-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
	if (!$servicePrincipalConnection){
		$ErrorMessage = "Connection $connectionName not found."
		throw $ErrorMessage
	} else {
		Write-Error -Message $_.Exception
		throw $_.Exception
	}
}

$storageAccountName ="<SA NAME>"
$storageAccountKey ="<SA KEY>"
$containerName = "mycontainer"
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey 
$vmReportName = "VMReport_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv" 

# $container = New-AzStorageContainer  -Name $containerName -context $context 

$VMs = Get-AzVM

$vmOutput = $VMs | ForEach-Object {
	[PSCustomObject]@{
		"VM Name" = $_.Name
		"VM Type" = $_.StorageProfile.osDisk.osType
		"VM Profile" = $_.HardwareProfile.VmSize
		"VM OS Disk Size" = $_.StorageProfile.OsDisk.DiskSizeGB
		"VM Data Disk Size" = ($_.StorageProfile.DataDisks.DiskSizeGB) -join ','
	}
}
$vmOutput | Export-Csv "$Env:temp/$vmReportName" -NoTypeInformation
Set-AzStorageBlobContent -Container $containerName -File "$Env:temp\$vmReportName" -context $context
 
Get-AzStorageBlob -Container $containerName -Blob $vmReportName -Context $context | Get-AzStorageBlobContent -force -Destination $env:temp -context $context

$CSVImport = Import-Csv "$Env:temp\$vmReportName"
$CSVImport