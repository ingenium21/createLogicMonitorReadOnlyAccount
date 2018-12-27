<#
.SYNOPSIS
	Add Logic Monitor Local Accounts to ESX Hosts.
.DESCRIPTION
	Connects to VCenter to get a list of ESXi hosts, check for the Logic Monitor account
    if it does not exist, create it and set its role. If it does exist, set the password,
    Description and verify the account is readonly.
.AUTHOR
  Renato Regalado 12/27/2018
#>
Param (
	[Parameter(Mandatory = $True, Position = 0)]
	[string]$vCenter,
	[Parameter(Mandatory = $False, Position = 1)]
	[string]$vCenterUser,
	[Parameter(Mandatory = $False, Position = 2)]
	[string]$vCenterPass
	)

$ErrorActionPreference = "STOP"
#Load the VMWare powerCLI snapins.
$powerCLIModule = get-module -listavailable | where {$_.Name -eq 'VMware.PowerCLI'}
if($powerCLIModule){
import-module VMware.PowerCLI
}
else {
install-module VMware.PowerCLI
import-module VMware.PowerCLI
}



#Skip the SSL check
Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -WebOperationTimeoutSeconds -1 -Confirm:$false | Out-Null

#Connect to vCenter
Write-Host "Connecting to VCenter Server"
$global:VIServer = Connect-VIServer -server $vCenter #-Protocol https -User $vCenterUser -Password $vCenterPass

if($VIServer)
{
    #Get a list of ESXi Hosts
    Write-Host "Connected To VCenter Server"
    Write-Host "Getting List of ESXi Hosts"
    $esxlist = Get-VMHost -Server $VIServer

    #Loop through each host
    foreach($esx in $esxlist){
        Write-Host "checking users for host: $esx"
		$ESXiServer = Connect-VIServer -Server $esx -User root -Password '{{root password}}'
		$accounts = get-vmHostAccount -server $ESXiServer -errorAction silentlyContinue
		write-host $accounts
}
}
else
{
	Write-Host "ERROR: Unable to connect to vCenter"
}
