configuration ADDSExistingDomain
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xActiveDirectory'
    Import-DSCResource -ModuleName 'xPendingReboot'
    
    $dscDomainName = Get-AutomationVariable -Name 'DomainName'
    $InternalDomainControllerIP = Get-AutomationVariable -Name 'DCIPAddress'
    $dscDomainAdmin = Get-AutomationPSCredential -Name 'DomainAdmin'
    $SafeModeAdminCreds = Get-AutomationPSCredential -Name 'SafeModeAdminCreds'
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
                  DomainName = $dscDomainName 
                  DomainUserCredential= $dscDomainAdmin
                  RetryCount = $RetryCount
                  RetryIntervalSec = $RetryIntervalSec
                  DependsOn = "[WindowsFeature]ADDS"
            }

            xADDomainController ReplicaDC 
            { 
                 DomainName = $dscDomainName 
                 DomainAdministratorCredential = $dscDomainAdmin 
                 SafemodeAdministratorPassword = $SafeModeAdminCreds.Password
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
