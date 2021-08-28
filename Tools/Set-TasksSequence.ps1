<#
	.SYNOPSIS
	 This script enable all tasks in the sequence tasks files.

	.DETAILS
	 This script enable all tasks in the sequence tasks files. 
	 This script must be run from the .\Tools folder as it uses relative path.

	.PARAMETER TaskFile
	 the xml task file to be used. The file should be located in ..\Configs.

	.PARAMETER Activate
	 Use this parameter to instruct the script to enable ALL Tasks in the Sequence section.

	.PARAMETER Deactivate
	 This is the default behavior for this script.
	 Use this parameter to instruct the script to disable ALL Tasks in the Sequence section.

	.NOTES
	 Version: 01.00.000
	    Date: 2021/08/27
	  Author: loic.veirman@mssec.fr
#>

Param(
	[Parameter(mandatory=$false)]
	[String]
	$TaskFile="TasksSequence_HardenAD.xml",

	[Parameter(mandatory=$false)]
	[switch]
	$Activate,

	[Parameter(mandatory=$false)]
	[switch]
	$Deactivate
)

##.Setup Error Trapping
$errorCode=0
$ErrorMess=""

##.Setup logging value
$logFile="..\Logs\Enable-TasksSequence.log"
$logData=@()

##.Startup Screen
#-Loading Header (yes, a bit of fun)
$SchedulrConfig = [xml](get-content ..\Configs\Configuration_HardenAD.xml)
$LogoData = Get-Content ("..\Configs\" + $SchedulrConfig.SchedulerSettings.ScriptHeader.Logo.file)
$PriTxCol = "Green"

$MaxLength = 0

foreach ($line in $LogoData)
{
    Write-Host $line -ForegroundColor $PriTxCol
    if ($line.length -gt $MaxLength) { $MaxLength = $line.Length }
}
Write-Host "`n ================================" -ForegroundColor Magenta
Write-Host " MASS TASKS SEQUENCE MODIFICATION" -ForegroundColor Yellow
Write-Host " --------------------------------" -ForegroundColor DarkGray
Write-Host "  Author: " -NoNewline -ForegroundColor Gray
Write-Host "loic.veirman@mssec.fr" -ForegroundColor Cyan
Write-Host " Version: " -NoNewline -ForegroundColor Gray
Write-Host "01.00.000" -ForegroundColor Cyan
Write-Host " ================================`n" -ForegroundColor Magenta

##.Init log
$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t================================="
$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t=== SCRIPT START"
$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t=== "
$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t=== PARAMETER TaskFile..: $TaskFile"
$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t=== PARAMETER Activate..: $Activate"
$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t=== PARAMETER Deactivate: $Deactivate"
$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t================================="

##.Set Action to perform
if ((-not($Activate) -and -not($Deactivate)) -or $Deactivate)
{
	Write-Host " The script will now " -NoNewline
	Write-Host "deactivate" -BackgroundColor DarkRed -ForegroundColor Gray -NoNewline
	Write-Host " all tasks from the sequence inputs..."

	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t+-----------------------------------+"
	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t| The script will disable all tasks |"
	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t+-----------------------------------+"
	$newValue = "No"
	$oldValue = "Yes"

} Else {
	Write-Host "The script will now " -NoNewline
	Write-Host "activate" -BackgroundColor DarkGreen -ForegroundColor Gray -NoNewline
	Write-Host " all tasks from the sequence inputs..."

	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t}----------------------------------+"
	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t| The script will enable all tasks |"
	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`t  `t+----------------------------------+"
	$newValue = "Yes"
	$oldValue = "No"
}

##.Check if the file exists
if (Test-Path ..\configs\$TaskFile)
{
	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`tOK`tTaskFile: is present"
} Else {
	$errorCode=2
	$ErrorMess="Could not find file in .\..\configs"
	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`tKO`tTaskFile: is missing (.\..\configs\$TaskFile)"
	$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`tKO`tTaskFile: Error Code: $errorCode"
}

##.Script will continue if the file exists
if ($errorCode -ne 2)
{
	##.Opening the XML file
	$xmlFile = [xml](Get-Content ..\configs\$TaskFile)
	$xmlData = Get-Content ..\configs\$TaskFile

	if ($xmlFile.Settings.Sequence)
	{
		$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`tOK`t<Sequence>: the section is present."

		##.Setting all tasks in the sequence section
		$xmlData = $xmlData -replace "<TaskEnabled>$oldValue</TaskEnabled>","<TaskEnabled>$newValue</TaskEnabled>"

		##.Export modified file
		Try {
			##.Backup Existing file
			$bkpID = (Get-Date -Format "yyyyMMddhhmmssff")
			Copy-Item ..\Configs\$TaskFile ..\Configs\$TaskFile-$bkpID.xml

			##.Updating file
			Set-Content -Path ..\configs\$TaskFile -Value $xmlData
			$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`tOK`tTaskFile: Successfully modified."
			$errorCode = 0
			$ErrorMess = "File rewritten successfully"

		} Catch {
			$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`tOK`tTaskFile: Failed to rewrite the xml file."
			$errorCode = 1
			$ErrorMess = "Failed to rewrite $TaskFile!"
		}
	
	} Else {
		$errorCode=2
		$ErrorMess="The section <Sequence></Sequence> is missing."
		$logData += (Get-Date -UFormat "%Y-%m-%d %T ") + "`tKO`t<Sequence>: the section is missing."
	}
}

##.End of Script
$logData | Out-File $logFile -Append

Switch ($errorCode)
{
	0 { $color = "Green" }
	1 { $color = "Magenta" }
	2 { $color = "Red" }
}

Write-Host "`n Return Code: " -NoNewline
Write-Host $errorCode -ForegroundColor $color
Write-Host " Return Mesg: " -NoNewline 
Write-Host $ErrorMess -ForegroundColor $color
Write-Host "`n Script's done!`n" -ForegroundColor Yellow