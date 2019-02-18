<#
	.SYNOPSIS
		Gets logical disks' information from a computer.
	.DESCRIPTION
		This script retrieves DeviceID, VolumeName, SizeGB, FreeSpaceGB, PercentFree, UsedSpaceGB and PercentUsed logical disk information
		from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-Disks.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-Disks
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-logicaldisk
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

	# Create a custom object to hold the disk information.
	$diskInfo = [pscustomobject]@{
		Computer = $ComputerName
		DeviceID = ""
		VolumeName  = ""
		SizeGB = ""
		FreeSpaceGB = ""
		PercentFree = ""
		UsedSpaceGB = ""
		PercentUsed = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the disks' information.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_LogicalDisk class.
		Try
		{
			
			# Get the logical disks' information.
			$logicalDisks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_LogicalDisk results were obtained, then continue.
		If (!$wmiError)
		{
			
			# Iterate through each logical disk found.
			ForEach ($disk in $logicalDisks)
			{
			
				# Only use local disk types (not network, DVD/CD, or removable types).
				If ($disk.DriveType -eq 3)
				{
				
					# Get the disk information.
					$freeSpace = [math]::round($disk.Freespace/1GB, 0)
					$size = [math]::round($disk.size/1GB, 0)
					$usedSpace = [math]::round($size, 0)-[math]::round($freeSpace, 0)
					$percentUsed = [math]::round(($usedSpace/$size*100), 0)
					$percentFree = [math]::round(($freeSpace/$size*100), 0)
					$percentUsed = "$PercentUsed%"
					$percentFree = "$PercentFree%"
					
					# Add the disk information to the object.
					$diskInfo = [pscustomobject]@{
						Computer = $ComputerName
						DeviceID = $disk.DeviceID
						VolumeName  = $disk.VolumeName
						SizeGB = $size
						FreeSpaceGB = $freeSpace
						PercentFree = $percentFree
						UsedSpaceGB = $usedSpace
						PercentUsed = $percentUsed
						ScriptStatus = "OK"
					}
					
					# Add the object to the final results.
					$results += $diskInfo
				}
			}
		}
		Else
		{ 
			
			# Failed to get logical disks' information.
			$diskInfo.ScriptStatus = "Failed - WMI Class: Win32_Logical Disk - $wmiError"
			
			# Update the results.
			$results += $diskInfo
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$diskInfo.ScriptStatus = "Failed - Could not connect to the computer"
		
		# Update the results.
		$results += $diskInfo
	}
	
	# General script failure.
	If ($diskInfo.ScriptStatus -eq "Failed - Script failed to complete.") 
	{
		
		# Update the results.
		$results += $diskInfo
	}

	# Create the header for the HTML output of the results. The "@ at the end must be leftmost on the line or powershell won't recognize it properly.
	$header = @" 
		<style>
		#tblToolOutput TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-family:verdana; 
		font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; text-align:center; 
		background-color:#39ac6b; color:white; font-weight:bold;} #tblToolOutput TD {border-width: 1px; padding: 3px; border-style: solid; 
		border-color: black;text-align:left;} #tblToolOutput td:nth-child(2){text-align:right;} #tblToolOutput td:nth-child(3){text-align:right;}
		#tblToolOutput td:nth-child(4){text-align:right;} #tblToolOutput td:nth-child(5){text-align:right;} 
		#tblToolOutput td:nth-child(6){text-align:right;} #tblToolOutput td:nth-child(7){text-align:right;} 
		#tblToolOutput td:nth-child(8){text-align:right;}
		</style>
		<div id=tblToolOutput>
"@
	
	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$diskInfo = $results  | Select-Object Computer, DeviceID, VolumeName, SizeGB, FreeSpaceGB, PercentFree, UsedSpaceGB, PercentUsed, ScriptStatus | `
		ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $diskInfo
}
