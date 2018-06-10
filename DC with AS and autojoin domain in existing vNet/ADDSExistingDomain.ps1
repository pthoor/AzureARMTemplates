configuration ADDSExistingDomain
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xActiveDirectory'
    Import-DSCResource -ModuleName 'xPendingReboot'
    
    $dscDomainName = Get-AutomationVariable -Name 'DomainName'
    $InternalDomainControllerIP = Get-AutomationVariable -Name 'DCIPAddress'
    $dscDomainAdmin = Get-AutomationPSCredential -Name 'DomainAdmin'
    $SafeModePassword = $dscDomainAdmin
    $dscDomainJoinAdminUsername = $dscDomainAdmin.UserName
    $dscDomainJoinAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist "$dscDomainName\$dscDomainJoinAdminUsername", $dscDomainAdmin.Password
    $RetryCount = 10
    $RetryIntervalSec = 15
    
    node "localhost" {

            WindowsFeature RSAT 
            {
                  Ensure = "Present"
                  Name = "RSAT"
            }

            WindowsFeature ADDS
            {
                   Ensure = "Present"
                   Name   = "AD-Domain-Services"
            }
            
            xWaitForADDomain DscForestWait 
            { 
                  DomainName = $DomainName 
                  DomainUserCredential= $dscDomainAdmin
                  RetryCount = $RetryCount
                  RetryIntervalSec = $RetryIntervalSec
                  DependsOn = "[WindowsFeature]ADDS"
            }

            xADReplicationSubnet AzureSubnet
            {
                Ensure = "Present"
                Name = "10.0.1.0/16"
                Site = "AzureSite"
            }

            xADReplicationSite AzureSite
            {
                Ensure = "Present"
                Name = "AzureSite"
                DependsOn = "[xADReplicationSubnet]AzureSubnet"
            }

            xADDomainController ReplicaDC 
            { 
                 DomainName = $DomainName 
                 DomainAdministratorCredential = $dscDomainAdmin 
                 SafemodeAdministratorPassword = $SafeModePassword
                 DatabasePath = "C:\NTDS"
                 LogPath = "C:\NTDS"
                 SysvolPath = "C:\SYSVOL"
                 DependsOn = "[xWaitForADDomain]DScForestWait"
            }

            xPendingReboot Reboot1
            { 
                Name = "RebootServer"
                DependsOn = "[xADDomainController]ReplicaDC"
            }
    }

}
