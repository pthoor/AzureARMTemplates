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
    $RetryCount = 20 
    $RetryIntervalSec = 45 
    
    node "localhost" { 
        WindowsFeature RSAT 
        { 
            Ensure = "Present" 
            Name = "RSAT" 
        } 
        WindowsFeature ADDS 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services" 
        } 
        xWaitForADDomain DscForestWait 
        { 
            DomainName = $dscDomainName 
            DomainUserCredential= $dscDomainAdmin 
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec 
            DependsOn = "[WindowsFeature]ADDS" 
        } 
        xADReplicationSubnet AzureSubnet 
        { 
            Ensure = "Present" 
            Name = "10.0.1.0/24" 
            Site = "AzureSite"
            DependsOn = "[xADReplicationSite]AzureSite"
        } 
        xADReplicationSite AzureSite 
        { 
            Ensure = "Present" 
            Name = "AzureSite" 
             
        } 
        xADDomainController ReplicaDC 
        { 
            DomainName = $dscDomainName 
            DomainAdministratorCredential = $dscDomainAdmin 
            SafemodeAdministratorPassword = $SafeModePassword 
            DatabasePath = "C:\NTDS" 
            LogPath = "C:\NTDS" 
            SysvolPath = "C:\SYSVOL" 
            SiteName = "AzureSite"
            DependsOn = "[xWaitForADDomain]DScForestWait","[xADReplicationSite]AzureSite"
        } 
        xPendingReboot Reboot1 
        { 
            Name = "RebootServer" 
            DependsOn = "[xADDomainController]ReplicaDC" 
        } 
    } 
} 