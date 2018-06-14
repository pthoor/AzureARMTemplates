#Requires -Version 3.0
#Requires -Module AzureRM.Resources

Param(
	[Parameter(Mandatory=$true)]
    [string] $dscConfigFile,
	[string] $dscAutomationAccount = "TestAutomation",
	[string] $dscResourceGroup = "test-rg",
	[bool] $Force = $false
)

Function Import-DscConfiguration ($dscConfigFile, $dscAutomationAccount, $dscResourceGroup) {
	$dscConfigFileFull = (Get-Item $dscConfigFile).FullName
	$dscConfigFileName = [io.path]::GetFileNameWithoutExtension($dscConfigFile)
	$dsc = Get-AzureRmAutomationDscConfiguration -ResourceGroupName $dscResourceGroup -AutomationAccountName $dscAutomationAccount -Name $dscConfigFileName -erroraction 'silentlycontinue'
	if ($dsc -and !$Force) { 
		Write-Information -MessageData  "Configuration $dscConfigFileName Already Exists"
	} else {
		Write-Information -MessageData  "Importing & compiling configuration $dscConfigFileName"
		Import-AzureRmAutomationDscConfiguration -AutomationAccountName $dscAutomationAccount -ResourceGroupName $dscResourceGroup -Published -SourcePath $dscConfigFileFull -Force
		$CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $dscResourceGroup -AutomationAccountName $dscAutomationAccount -ConfigurationName $dscConfigFileName -ConfigurationData $ConfigData
		while($null -eq $CompilationJob.EndTime -and $null -eq $CompilationJob.Exception)           
		{
			$CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
			Start-Sleep -Seconds 3
			Write-Information -MessageData "."
		}
		Write-Information -MessageData  "!"
		$CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput
	}
}

Import-DscConfiguration $dscConfigFile $dscAutomationAccount $dscResourceGroup