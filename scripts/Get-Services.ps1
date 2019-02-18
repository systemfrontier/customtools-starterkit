<#
	.SYNOPSIS
		Gets services' information from a computer.
	.DESCRIPTION
		This script retrieves ServiceName, DisplayName, Description, PathName, State, StartMode	and StartName information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-Services.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-Services
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-service
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

	# Create a custom object to hold schedule task information.
	$serviceInfo = [pscustomobject]@{
		Computer = $ComputerName
		ServiceName = ""
		DisplayName  = ""
		Description = ""
		PathName = ""
		State = ""
		StartMode = ""
		StartName = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the services' information.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_Service class.
		Try
		{
			
			# Get services information.
			$Services = Get-WmiObject -Class Win32_Service -ComputerName $ComputerName -ErrorAction Stop                      
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
	
		# If Win32_Service results were obtained, then continue.
		If (!$wmiError)
		{

			# Iterate through each service.
			ForEach ($service in $services)
			{
			
				# Add the service information to the object.
				$serviceInfo = [pscustomobject]@{
					Computer = $ComputerName
					ServiceName = $service.Name
					DisplayName  = $service.DisplayName
					Description = $service.Description
					PathName = $service.PathName
					State = $service.State
					StartMode = $service.StartMode
					StartName = $service.StartName
					ScriptStatus = "OK"
				}
				
				# Add the object to the final results.
				$results += $serviceInfo
			}
		}
		Else
		{ 
			
			# Failed to get services information.
			$serviceInfo.ScriptStatus = "Failed - WMI Class: Win32_Service - $wmiError"
			
			# Update the results.
			$results += $serviceInfo
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$serviceInfo.ScriptStatus = "Failed - Could not connect to computer."
		
		# Update the results.
		$results += $serviceInfo
	}
	
	# General script failure.
	If ($serviceInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $serviceInfo
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
	$services = $results | Sort ServiceName | Select-Object Computer, ServiceName, State, StartMode, StartName, DisplayName, Description, PathName, ScriptStatus | `
		ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $services
}
