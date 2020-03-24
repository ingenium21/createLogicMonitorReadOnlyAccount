<#
.SYNOPSIS
	Add Logic Monitor Local Accounts to ESX Hosts.
.DESCRIPTION
	Connects to VCenter to get a list of ESXi hosts, check for the Logic Monitor account
    if it does not exist, create it and set its role. If it does exist, set the password,
    Description and verify the account is readonly.
.AUTHOR
	Renato Regalado 12/26/2018
.CHANGE DATE
	03/24/2020
.CHANGED BY
	Renato Regalado 12/26/2018
	Renato Regalado 03/24/2020
.CHANGELOG
	- updated the module configuration so that it imports vmware.powercli, the latest powercli module.
	  added instructions for loading the powercli module.
	- Refactoring code so that certain things are saved into functions and imported as modules for cleaner code
.NOTES
	If you see anything between two curley brackets {{example}}  that means is a descriptor and you need to supply the correct information.
#>
Param (
	[Parameter(Mandatory = $True, Position = 0)]
	[string]$vCenter,
	[Parameter(Mandatory = $False, Position = 1)]
	[string]$vCenterUser = "administrator@vsphere.local",
	[Parameter(Mandatory = $False, Position = 2)]
	[string]$vCenterPass,
	[Parameter(Mandatory = $False, position = 3)]
	[switch]$UseActiveDirectory,
	[Parameter(Mandatory = $True, position = 4)]
	[String]$ROAcctName = "RoAcct",
	[Parameter(Mandatory = $True, position = 5)]
	[String]$ROAcctPass,
	[Parameter(Mandatory = $True, position = 6)]
	[String]$rootUser = "root",
	[Parameter(Mandatory = $True, position = 7)]
	[String] $rootpass
	)

$ErrorActionPreference = "STOP"

#import all modules in the modules folder
$modules = Get-ChildItem .\Modules
Import-module $modules

#load install-powercli module
install-powercli

#Skip the SSL check
Set-PowerCLIConfiguration -scope AllUsers -InvalidCertificateAction:Ignore -WebOperationTimeoutSeconds -1 -Confirm:$false | Out-Null


#LogicMonitor Account Info
$accountDescription = "Logic Monitor Account"


#Connect to vCenter
Write-Host "Connecting to VCenter Server" -ForegroundColor Yellow
if($UseActiveDirectory){
	$global:VIServer = Connect-VIServer -Server $Vcenter
}
else{
	$password = ConvertTo-SecureString -String $vCenterPass -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($VcenterUser, $password)
	$global:VIServer = Connect-VIServer -Credential $cred -Server $VcenterServer
}

if($VIServer)
{
    #Get a list of ESXi Hosts
    Write-Host "Connected To VCenter Server!" -ForegroundColor Green
    Write-Host "Getting List of ESXi Hosts" -ForegroundColor Yellow
    $esxlist = Get-VMHost -Server $VIServer

    #Loop through each host
    foreach($esx in $esxlist){
		Write-Host "Adding Account to ESXi Host: $esx"
		$rootPassword = ConvertTo-SecureString -String $rootpass -AsPlainText -Force
		$rootCred = New-Object System.Management.Automation.PSCredential($rootUser, $rootPassword)
		$ESXiServer = Connect-VIServer -Server $esx -Credential $rootCred
		if ($ESXiServer)
		{
	        New-ReadOnlyUser($ROAcctName, $ROAcctPass, $accountDescription, $ESXiServer)
	        }
			Disconnect-VIServer -Server $ESXiServer -Confirm:$false
		}else {
			Write-Host "Unable to connect to host: $esx" -ForegroundColor Red -BackgroundColor Black
		}
}
else
{
	Write-Host "ERROR: Unable to connect to vCenter" -ForegroundColor Red -BackgroundColor Black
}
