
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
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey 
# $container = New-AzStorageContainer  -Name "mycontainer" -context $context 

$vmReportName = "VMReport_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv" 
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
Set-AzStorageBlobContent -Container "mycontainer" -File "$Env:temp\$vmReportName" -context $context
 
Get-AzStorageBlob -Container "mycontainer" -Blob $vmReportName -Context $context | Get-AzStorageBlobContent -force -Destination $env:temp -context $context

$CSVImport = Import-Csv "$Env:temp\$vmReportName"
$CSVImport