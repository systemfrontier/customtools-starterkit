<#
	.SYNOPSIS
		Stops a process on a computer.
	.DESCRIPTION
		A process is terminated on a target computer with this script.
	.PARAMETER ComputerName
		The name of the target computer.
	.PARAMETER ProcessName
		The name of the process on the target computer.
	.EXAMPLE
		.\StopProcess.ps1 -ComputerName "COMP01" -ProcessName "Chrome.exe"
	.NOTES
		Name:		StopProcess
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-process
#>

# Provides additional functionality.
[Cmdletbinding()]

# Get the parameters.
Param( 
	[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
	[String]$ComputerName,
	[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
	[String]$ProcessName
)

Process
{  

	# Remove any leading/trailing spaces from $ComputerName and $ProcessName.
	$ComputerName = $ComputerName.trim()
	$ProcessName = $ProcessName.trim()
	
	# Clear the error variable.
	$error.Clear()
	
	# Set the timeout period (in seconds) to allow the process to terminate.
	$timeout = 20
	
	# Create a custom object to hold the stop process results.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		ProcessName = $ProcessName
		Status  = ""
		ScriptStatus = "Failed - Script failed to complete."
	}
	
	# Check connection to the computer.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_Process class.
		Try
		{
			
			# Get processes information.
			$processes = Get-WMIObject -Class Win32_Process -Filter "Name='$ProcessName'" -ComputerName $ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_Process results were obtained, then continue.
		If ($processes)
		{	
			
			# Iterate through each process.
			ForEach ($process in $processes){
			
				# Stop the process.
				$process.Terminate() | out-null
			}
			
			# Give the process time to terminate.
			Start-Sleep -s $timeout
			
			# Attempt to get information from the Win32_Process class (to determine if the process still exists).
			Try
			{
				
				# Get processes information.
				$processes = Get-WMIObject -Class Win32_Process -Filter "Name='$ProcessName'" -ComputerName $ComputerName -ErrorAction Stop
			}
			Catch
			{
				
				# Capture the error.
				$wmiError = [string]$($error[0].Exception.Message)
			}
			
			# Determine process status.
			If ($processes)
			{
			
				# Process is still running.
				$results.Status = "Failed - process: $ProcessName was still running 15 seconds after attempting to terminate it."
				$results.ScriptStatus = "WMI connection was okay."
			}
			ElseIf ($processes.count -eq 0) 
			{ 
			
				# Process was terminated.
				$results.Status = "Process was terminated successfully."
				$results.ScriptStatus = "OK"
			}
			Else
			{
				
				# Process status is undetermined.
				$results.Status = "Unable to determine if process was terminated."
				$results.ScriptStatus = "Failed - WMI Class: Win32_Process - $wmiError"
			}
		}
		ElseIf ($processes.count -eq 0)
		{
		
			# Process was not running initially.
			$results.Status = "Process was not running."
			$results.ScriptStatus = "OK"
		}
		Else
		{
			
			# Process was unable to be terminated.
			$results.Status = "Failed - Unable to terminate the process."
			$results.ScriptStatus = "Failed - WMI Class: Win32_Process - $wmiError"
		}	
	}
	Else
	{
		
		# Failed to connect to the computer.
		$results.ScriptStatus = "Failed - Could not connect to the computer."
	}
	
	# Create the header for the HTML output of the results. 
	$header = "<style>`
				#tblToolOutput TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;`
				font-family:verdana; font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; `
				border-color: black; text-align:left; background-color:#39ac6b; color:white; font-weight:bold;} `
				#tblToolOutput TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}`
				</style>`
				<div id=tblToolOutput>"
	
	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$stopProcess = $results | Select-Object Computer, ProcessName, Status, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent `
		$footer
	
	# Display the results.
	Write-Output $stopProcess
}
