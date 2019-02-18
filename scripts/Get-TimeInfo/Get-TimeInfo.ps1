<#
	.SYNOPSIS
		Gets time information from a computer.
	.DESCRIPTION
		This script retrieves Uptime, LastBootTime, LocalTime, TimeZoneDescription, TimeZoneDayLightName, and
		TimeZoneStandardName information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-TimeInfo.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-TimeInfo
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-operatingsystem
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/Win32-TimeZone
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
	
	# Create a custom object to hold the time information.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		Uptime = ""
		LastBootTime = ""
		LocalTime = ""
		TimeZoneDescription = ""
		TimeZoneDayLightName = ""
		TimeZoneStandardName = ""
		ScriptStatus = "Failed - Script failed to complete."
	}
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_OperatingSystem class.
		Try
		{
			
			# Get operating system information.
			$operatingSystem = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_OperatingSystem results were obtained, then continue.
		If (!$wmiError)
		{	

			# Get the lastboottime.
			$LastBootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($operatingSystem.LastBootupTime)
			$results.LastBootTime = $LastBootTime
			
			# Get the local time.
			$remotetime = [System.Management.ManagementDateTimeConverter]::ToDateTime($operatingSystem.LocalDateTime)
			$results.LocalTime = $remotetime
			
			# Get the uptime.
			$bootDiff = $remotetime - $LastBootTime
			$results.UpTime = "{0:00} days {1:00} hours {2:00} minutes {3:00} seconds" -f $bootDiff.Days,$bootDiff.Hours,$bootDiff.Minutes,`
				$bootDiff.Seconds
			
			# Attempt to get the timezone info.
			Try
			{
				
				# Get time zone information.
				$timeZone = Get-WMIObject -Class Win32_TimeZone -ComputerName $ComputerName -ErrorAction Stop
			}
			Catch
			{
				
				# Capture the error.
				$wmiError = [string]$($error[0].Exception.Message)
			}
			
			# If timezone info was obtained, then continue.
			If (!$wmiError)
			{
				
				# Put the time zone information into the final results.
				$results.TimeZoneDescription = $timeZone.Description
				$results.TimeZoneDaylightName = $timeZone.DaylightName
				$results.TimeZoneStandardName = $timeZone.StandardName
				$results.ScriptStatus = "OK"
			}
			Else
			{
				
				# Failed to get time zone information.
				$results.ScriptStatus = "Failed - WMI Class: Win32_TimeZone - $wmiError"
			}
		}
		Else
		{
			
			# Failed to get operating system information.
			$results.ScriptStatus = "Failed - WMI Class: Win32_OperatingSystem - $wmiError"
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$results.ScriptStatus = "Failed - Could not connect to computer."
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
	$timeInfo = $results | Select-Object Computer, Uptime, LastBootTime, LocalTime, TimeZoneDescription, TimeZoneDaylightName, TimeZoneStandardName, `
		ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $timeInfo
}
