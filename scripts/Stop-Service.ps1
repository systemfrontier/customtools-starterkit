<#
	.SYNOPSIS
		Stops a service on a computer.
	.DESCRIPTION
		A service is stopped on a target computer with this script.
	.PARAMETER ComputerName
		The name of the target computer.
	.PARAMETER ServiceName
		The name of the service on the target computer.
	.EXAMPLE
		.\Stop-Service.ps1 -ComputerName "COMP01" -ServiceName "Spooler"
	.EXAMPLE
		.\Stop-Service.ps1 -ComputerName "COMP01" -ServiceName "Print Spooler"	
	.NOTES
		Name:		Stop-Service
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-service
	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service?view=powershell-6
#>

# Provides additional functionality.
[Cmdletbinding()]

# Get the parameters.
Param( 
	[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
	[String]$ComputerName,
	[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
	[String]$ServiceName
)

Process
{

	# Remove any leading/trailing spaces from $ComputerName and $ServiceName.
	$ComputerName = $ComputerName.trim()
	$ServiceName = $ServiceName.trim()
	
	# Initialize the variables.
	$error.Clear()
	$wmiError = ""
	
	# Set the maximum wait time (in seconds) for the service to stop.
	$timeout = "00:00:20"
	
	# Create a custom object to hold the stop service results.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		Service = $ServiceName
		Status  = "Unable to stop the service."
		ScriptStatus = "Failed - Script failed to complete."
	}
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to connect to the Win32_Service class.
		Try
		{
			
			# Get service information.
			$serviceStart = Get-WmiObject -Class Win32_Service -ComputerName $ComputerName -Filter "Name='$ServiceName' OR `
				Displayname='$ServiceName'" -ErrorAction Stop
		}
		Catch
		{
		
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_Service results were obtained, then continue.
		If (!$wmiError)
		{
		
			# If the service isn't disabled, then continue.
			If ($serviceStart.StartMode -ne "Disabled")
			{
				# Attempt to get information from Get-Service.
				Try
				{
					
					# If $ServiceName equals $serviceStart.Name, then continue
					If ($serviceStart.Name -eq $ServiceName)
					{
						
						# Connect to the service object using the name property.
						$service = Get-Service -Name "$ServiceName" -ComputerName $ComputerName -ErrorAction Stop
					}
					Else
					{
						
						# Connect to the service object using the displayname property.
						$service = Get-Service -Displayname "$ServiceName" -ComputerName $ComputerName -ErrorAction Stop
					}
				}
				Catch
				{
					
					# Capture the error.
					$wmiError = [string]$($error[0].Exception.Message)
				}
				
				# If Get-Service results were obtained, then continue.
				If (!$wmiError)
				{
					
					# Service startmode is set to enabled.  Determine service status.
					If ($service.Status -ne "Stopped")
					{
						
						# Service isn't stopped.  Attempt to stop it.
						($service.Stop()) | out-null
						
						# Wait for the timeout period and return a new service status.
						$service.WaitForStatus('Stopped',$timeout)
						
						# Determine new service status.
						If ($service.Status -eq "Stopped")
						{
							
							# Service has been stopped.
							$results.Status = "Service Stopped Successfully."
							$results.ScriptStatus = "OK"
						}
						Else
						{
						
							# Service did not stop within the timeout period.
							$results.Status = "Service failed to stop within the timeout period: $timeout."
							$results.ScriptStatus = "WMI connection was okay."
						}
					}
					Else
					{
						
						# Service was already stopped.
						$results.Status = "Service is already stopped."
						$results.ScriptStatus = "OK"
					}
				}
				Else
				{
				
					# Failed to connect to the $service object.
					$results.ScriptStatus = "Failed - $WMIError."
				}
				
			}
			Else
			{
				
				# Service start mode is set to disabled, therefore we cannot stop it.
				$results.Status = "Service is disabled.  Cannot stop service."
				$results.ScriptStatus = "WMI connection was okay."
			}
		}
		Else
		{
			
			# Failed to connect to the $serviceStart object
			$results.ScriptStatus = "Failed - $WMIError."
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
	$stopService = $results | Select-Object Computer, Service, Status, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header `
		-PostContent $footer
	
	# Display the results.
	Write-Output $stopService
}
