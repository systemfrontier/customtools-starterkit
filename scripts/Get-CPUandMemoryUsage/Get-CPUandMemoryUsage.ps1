<#
	.SYNOPSIS
		Gets CPU and memory information from a computer.
	.DESCRIPTION
		This script retrieves CPUUsagePercent, MemoryUsagePercent, TotalMemoryMB, TopMemoryProcessName, TopMemoryProcessID, TopMemoryUsageMB, 
		TopMemoryUsagePercent and TopMemoryProcessOwner CPU and memory information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-CPUandMemoryUsage.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-CPUandMemoryUsage
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-operatingsystem
	.LINK		
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-processor
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
	
	# Create a custom object to hold the CPU and memory information.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		CPUUsagePercent = ""
		MemoryUsagePercent = ""
		TotalMemoryMB = ""
		TopMemoryProcessName = ""
		TopMemoryProcessID = ""
		TopMemoryUsageMB = ""
		TopMemoryUsagePercent = ""
		TopMemoryProcessOwner = ""
		ScriptStatus = "Failed - Script failed to complete."
	}
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_Processor class.
		Try
		{
			
			# Get the processor information.
			$cpu = Get-WmiObject -Class Win32_Processor -ComputerName $ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_Processor results were obtained, then continue.
		If (!$wmiError)
		{
			# Get CPU usage.
			$cpuUsage = [math]::Round(($cpu | Measure-Object -Property LoadPercentage -Average | Select -ExpandProperty Average),2)
			$results.CPUUsagePercent = "$cpuUsage%"
			
			# Attempt to get information from the Win32_OperatingSystem class.
			Try
			{
				
				# Get the operating system information.
				$os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
			} 
			Catch
			{
				
				# Capture the error.
				$wmiError = [string]$($error[0].Exception.Message)
			}
			
			# If Win32_OperatingSystem results were obtained, then continue.
			If (!$wmiError)
			{
				# Get memory amount and usage.
				$memUsage = "{0:N2}" -f [math]::Round((($os.TotalVisibleMemorySize - $OS.FreePhysicalMemory)*100)/$OS.TotalVisibleMemorySize,2)
				$totalMemoryMB = [math]::round(($OS.TotalVisibleMemorySize/1024),0)  # This variable is used in processes info collection as well.
				$results.MemoryUsagePercent = "$memUsage%"
				$results.TotalMemoryMB = $totalMemoryMB
				
				# Attempt to get information from the Win32_Process class.
				Try
				{
					
					# Get the processes' information.
					$processes = Get-WmiObject -Class Win32_Process -ComputerName $ComputerName -ErrorAction Stop
				}
				Catch
				{
					
					# Capture the error.
					$wmiError = [string]$($error[0].Exception.Message)
				}
				
				# If Win32_Process results were obtained, then continue.
				If (!$wmiError)
				{
					
					# Get process memory-related information.
					$topProcessByMemory = $processes | Sort-Object -Property ws -Descending | select -first 1 
					$topMemUsageMB = [math]::round($topProcessByMemory.WS / 1mb)
					$topMemUsagePercent = [math]::round(($topMemUsageMB/$totalMemoryMB*100),2)
					$topProcessByMemoryOwner = $topProcessByMemory.getowner().user
					$topMemoryProcessName = [String]$topProcessByMemory.processname
					$topMemoryProcessID = [String]$topProcessByMemory.ProcessID
					$results.TopMemoryProcessName = $topMemoryProcessName
					$results.TopMemoryUsageMB = $topMemUsageMB
					$results.TopMemoryUsagePercent = "$topMemUsagePercent%"
					$results.TopMemoryProcessID = $topMemoryProcessID
					$results.TopMemoryProcessOwner = $topProcessByMemoryOwner
					$results.ScriptStatus = "OK"
				}
				Else
				{
					
					# Failed to get processes' information.
					$results.ScriptStatus = "Failed when getting process info - $wmiError"
				}
			}
			Else
			{
				
				# Failed to get operating system information.
				$results.ScriptStatus = "Failed when getting memory info - $wmiError"
			}		
		}
		Else
		{
			
			# Failed to get processor information.
			$results.ScriptStatus = "Failed when getting CPU info - $wmiError"
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$results.ScriptStatus = "Failed to connect to the computer"
	}
	
	# Create the header for the HTML output of the results. The "@ at the end must be leftmost on the line or powershell won't recognize it properly.
	$header = @" 
		<style>
		#tblToolOutput TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-family:verdana; 
		font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; text-align:center; 
		background-color:#39ac6b; color:white; font-weight:bold;} #tblToolOutput TD {border-width: 1px; padding: 3px; border-style: solid; 
		border-color: black;text-align:left;} #tblToolOutput td:nth-child(2){text-align:right;}	#tblToolOutput td:nth-child(3){text-align:right;}
		#tblToolOutput td:nth-child(4){text-align:right;} #tblToolOutput td:nth-child(7){text-align:right;}	
		#tblToolOutput td:nth-child(8){text-align:right;}
		</style>
		<div id=tblToolOutput>
"@
	
	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$cpuMemUsage = $results | Select-Object Computer, CPUUsagePercent, MemoryUsagePercent, TotalMemoryMB, TopMemoryProcessName, TopMemoryProcessID, `
		TopMemoryUsageMB, TopMemoryUsagePercent, TopMemoryProcessOwner, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $cpuMemUsage
}
