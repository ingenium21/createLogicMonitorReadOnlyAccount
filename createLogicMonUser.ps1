<#
.SYNOPSIS
	Add Logic Monitor Local Accounts to ESX Hosts.
.DESCRIPTION
	Connects to VCenter to get a list of ESXi hosts, check for the Logic Monitor account
    if it does not exist, create it and set its role. If it does exist, set the password,
    Description and verify the account is readonly.
.AUTHOR
	Bob Trasatti - 12/21/2017
.CHANGE DATE
	11/06/2018
.CHANGED BY
	Renato Reglado 12/26/2018
.CHANGELOG
	updated the module configuration so that it imports vmware.powercli, the latest powercli module.
	added instructions for loading the powercli module.
.NOTES
	If you see anything between two curley brackets {{example}}  that means is a descriptor and you need to supply the correct information.
#>
Param (
	[Parameter(Mandatory = $True, Position = 0)]
	[string]$vCenter,
	[Parameter(Mandatory = $False, Position = 1)]
	[string]$vCenterUser,
	[Parameter(Mandatory = $False, Position = 2)]
	[string]$vCenterPass,
	[Parameter(Mandatory = $True, position = 3)]
	[String]$ROAcctName = "RoAcct",
	[Parameter(Mandatory = $True, position = 4)]
	[SecureString]$ROAcctPass
	)

$ErrorActionPreference = "STOP"

#load install-powercli module
. .\Modules\install-powercli.ps1
install-powercli

#LogicMonitor Account Info
$accountDescription = "Logic Monitor Account"


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
        Write-Host "Adding Account to ESXi Host: $esx"
		$ESXiServer = Connect-VIServer -Server $esx -User root -Password '{{root password}}'
		if ($ESXiServer)
		{
	        $rootFolder = Get-Folder -Name *root -Server $ESXiServer
	        $account = $null
	        Try{
	            $account = Get-VMHostAccount -Id $ROAcctName -Server $ESXiServer -ErrorAction Stop 
	            if($null -ne $account)
	            {
	                #Validate the password and description is set correctly
	                Set-VMHostAccount -UserAccount $account -Password $ROAcctPass -Description $accountDescription -Server $ESXiServer | Out-Null
	                $permission = Get-VIPermission -Entity $rootFolder -Principal $account -Server $ESXiServer
	                if($permission -ne "ReadOnly")
	                {
	                    New-VIPermission -Entity $rootFolder -Principal $account -Role "ReadOnly" -Server $ESXiServer | Out-Null
	                }
	            }
	        }
	        Catch{
	            $account = New-VMHostAccount -Server $ESXiServer -Id $ROAcctName -Password $ROAcctPass -Description $accountDescription -UserAccount -GrantShellAccess
	            New-VIPermission -Entity $rootFolder -Principal $account -Role "ReadOnly" -Server $ESXiServer | Out-Null
	        }
			Disconnect-VIServer -Server $ESXiServer -Confirm:$false
		}else {
			Write-Host "Unable to connect to host: $esx"
		}
	}
}
else
{
	Write-Host "ERROR: Unable to connect to vCenter"
}
