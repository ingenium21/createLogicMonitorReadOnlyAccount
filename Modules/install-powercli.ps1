#There are two ways to load the VMware PowerCli snapin and it depends on the powershell version. #
#if your version of powershell is 5.1 or above uncomment the following command.
#Load the VMWare powerCLI snapins.

function install-powercli{
    $powerCLIModule = get-module -listavailable | where-object {$_.Name -ieq 'vmware.powercli'}
    if($powerCLIModule){
        import-module VMware.PowerCLI
        #Skip the SSL check
        Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -WebOperationTimeoutSeconds -1 -Confirm:$false | Out-Null
    }
    else {
        install-module VMware.PowerCLI
        import-module VMware.PowerCLI
        #Skip the SSL check
        Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -WebOperationTimeoutSeconds -1 -Confirm:$false | Out-Null
    }
}