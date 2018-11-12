#Import-AzureRmAutomationModule -Name 'AzureAD' 
#Import-AzureRmAutomationModule -Name 'ImportExcel'
#Import-AzureRmAutomationModule -Name 'MSGraphIntuneManagement'

$IntuneCreds = Get-AutomationPSCredential 'IntuneCreds'

#$IntuneCreds = Get-Credential -Message "intune admin" -UserName "pierre@thoor.onmicrosoft.com"
$Username = $IntuneCreds.UserName
$Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $IntuneCreds.Password 

$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

$AuthToken = Get-MSGraphAuthenticationToken -Credential $Creds -ClientId $clientId


Function Get-ManagedDevices(){

    <#
    .SYNOPSIS
    This function is used to get Intune Managed Devices from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Intune Managed Device
    .EXAMPLE
    Get-ManagedDevices
    Returns all managed devices but excludes EAS devices registered within the Intune Service
    .EXAMPLE
    Get-ManagedDevices -IncludeEAS
    Returns all managed devices including EAS devices registered within the Intune Service
    .NOTES
    NAME: Get-ManagedDevices
    #>
    
    [cmdletbinding()]
    
    param
    (
        [switch]$IncludeEAS,
        [switch]$ExcludeMDM
    )
    
    # Defining Variables
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/managedDevices"
    
    try {
    
        $Count_Params = 0
    
        if($IncludeEAS.IsPresent){ $Count_Params++ }
        if($ExcludeMDM.IsPresent){ $Count_Params++ }
            
            if($Count_Params -gt 1){
    
            write-warning "Multiple parameters set, specify a single parameter -IncludeEAS, -ExcludeMDM or no parameter against the function"
            Write-Host
            break
    
            }
            
            elseif($IncludeEAS){
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
    
            }
    
            elseif($ExcludeMDM){
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'eas'"
    
            }
            
            else {
        
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
            Write-Warning "EAS Devices are excluded by default, please use -IncludeEAS if you want to include those devices"
            Write-Host
    
            }
    
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        
        }
    
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    }
    
    


$path = "$env:TEMP\Intune_test.xlsx"

$path

Get-ManagedDevices | Select-Object UserDisplayName, emailAddress, deviceName, complianceState, deviceType, operatingSystem, imei, serialNumber `
    | Export-Excel $path -AutoFilter -AutoSize -BoldTopRow -Numberformat 0 -ConditionalText $( 
        New-ConditionalText noncompliant -ConditionalTextColor yellow
        New-ConditionalText unknown -ConditionalTextColor yellow 
        )



Get-ManagedDevices | Select-Object UserDisplayName, emailAddress, deviceName, complianceState, deviceType, operatingSystem, imei, serialNumber
#Send-MailMessage -SmtpServer thoor-tech.mail.onmicrosoft.com -To "pierre@thoor.tech" -Subject "Mail from Automation" -From "pierre@thoor.onmicrosoft.com" -Attachments $path -Body "Test from automation" -Port 25

$subject = 'Mail from automation'
$Body = 'Test from automation'
$userid = 'pierre@thoor.onmicrosoft.com'

Send-MailMessage `
    -To 'pierre@thoor.tech' `
    -Subject $subject  `
    -Body $Body `
    -UseSsl `
    -Port 587 `
    -SmtpServer 'smtp.office365.com' `
    -From $userid `
    -BodyAsHtml `
    -Attachments $path `
    -Credential $IntuneCreds