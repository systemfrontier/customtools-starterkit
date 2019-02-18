<#
	.SYNOPSIS
		Gets processes' information from a computer.
	.DESCRIPTION
		This script retrieves ProcessName, CommandLine, CreationDate, ParentProcessId, Priority, ProcessId, ThreadCount and Path information
		from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-Processes.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-Processes
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
	[String]$ComputerName
)

Process
{  

	# Remove any leading/trailing spaces from $ComputerName.
	$ComputerName = $ComputerName.trim()
	
	# Clear the error variable.
	$error.Clear()

	# Create a custom object to hold the process information.
	$processInfo = [pscustomobject]@{
		Computer = $ComputerName
		ProcessName = ""
		CommandLine = ""
		CreationDate = ""
		ParentProcessId = ""
		Priority = ""
		ProcessId = ""
		ThreadCount = ""
		Path = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the hotfixes' information.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_Process class.
		Try
		{
			
			# Get processes information.
			$processes = Get-WmiObject -Class Win32_Process -ComputerName $ComputerName -ErrorAction Stop | Sort Name
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_Process results were obtained, then continue.
		If (!$wmiError)
		{

			# Iterate through each process.
			ForEach($process in $processes)
			{
			
				# Get the process creation date.
				$processCreationDate = $process.ConvertToDateTime($process.CreationDate)	
				
				# Add the process information to the object.
				$processInfo = [pscustomobject]@{
					Computer = $ComputerName
					ProcessName = $process.Name
					CommandLine = $process.CommandLine
					CreationDate = $processCreationDate
					ParentProcessId = $process.ParentProcessId
					Priority = $process.Priority
					ProcessId = $process.ProcessId
					ThreadCount = $process.ThreadCount
					Path = $process.Path
					ScriptStatus = "OK"
				}
				
				# Add the object to the final results.
				$results += $processInfo
			}
		}
		Else
		{
			
			# Failed to get processes information.
			$processInfo.ScriptStatus = "Failed - WMI Class: Win32_Process - $wmiError"
			
			# Update the results.
			$results += $processInfo
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$processInfo.ScriptStatus = "Failed - Could not connect to computer."
		
		# Update the results.
		$results += $processInfo
	}
	
	# General script failure.
	If ($processInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $processInfo
	}
	
	# Create the header for the HTML output of the results. The "@ at the end must be leftmost on the line or powershell won't recognize it properly.
	$Header = @" 
		<style>
		#tblToolOutput TABLE {table-layout:fixed;border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; 
		font-family:verdana; font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; 
		text-align:center; background-color:#39ac6b; color:white; font-weight:bold;} #tblToolOutput TD {border-width: 1px; padding: 3px; 
		border-style: solid; border-color: black;text-align:left;} #tblToolOutput td:nth-child(4){word-wrap: break-word;max-width:600px;
		overflow:auto;} #tblToolOutput td:nth-child(6){word-wrap: break-word;max-width:300px; overflow:auto;}
		</style>
		<div id=tblToolOutput>
"@

	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$processes = $results | Select-Object Computer, ProcessName, ProcessID, CommandLine, CreationDate, ParentProcessID, Priority, ThreadCount, `
		Path, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $processes
}
