Function New-ReadOnlyUser{
	param([String]$ROAcctName,
		  [String]$ROAcctPass,
		  [String]$accountDescription,
		  [String]$ESXiServer,
		  $rootFolder)
		  
	$account = $null
	Try{
		$account = Get-VMHostAccount -Id $ROAcctName -Server $ESXiServer -ErrorAction Stop 
		if($null -ne $account)
		{
			write-host "User already exists!" -ForegroundColor Green -BackgroundColor Black
			$Confirm = Read-Host -Prompt "Would you like to change the password and confirm Permissions?(y/n)"
			if(($confirm.ToUpper())[0] -eq 'Y'){
				#Validate the password and description is set correctly
				Set-VMHostAccount -UserAccount $ROAcctName -Password $ROAcctPass -Description $accountDescription -Server $ESXiServer | Out-Null
				$permission = Get-VIPermission -Entity $rootFolder -Principal $account -Server $ESXiServer
				if($permission -ne "ReadOnly")
				{
					New-VIPermission -Entity $rootFolder -Principal $account -Role "ReadOnly" -Server $ESXiServer | Out-Null
				}
			}
			else{
				Continue
			}
		}
	}
	Catch{
		Write-Host "User doesn't exist, creating..."
		$account = New-VMHostAccount -Server $ESXiServer -Id $ROAcctName -Password $ROAcctPass -Description $accountDescription -UserAccount -GrantShellAccess
		New-VIPermission -Entity $rootFolder -Principal $account -Role "ReadOnly" -Server $ESXiServer | Out-Null
	}
}