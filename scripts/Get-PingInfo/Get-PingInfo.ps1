<#
	.SYNOPSIS
		Tests ping status and gets IP address information from a computer.
	.DESCRIPTION
		This script attempts to ping a computer and retrieves PingStatus, IPv4Address, IPv6Address and the FQDN information.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-PingInfo.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-PingInfo
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/test-connection?view=powershell-6
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-computersystem
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

	# Create a custom object to hold the ping information.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		PingStatus = ""
		IPv4Address = ""
		IPv6Address = ""
		FQDN = ""
		ScriptStatus = "Failed - Script failed to complete."
	}
	
	# Attempt connection to the computer.
	Try
	{
		
		# Ping the computer.
		$pingCheck = test-connection $ComputerName -Count 1 -ErrorAction Stop
	}
	Catch
	{
		
		# Capture the error.
		$wmiError = [string]$($error[0].Exception.Message)
	}
	
	# If the connection was successful, then continue.
	If (!$wmiError)
	{

		# Ping was good.
		$results.PingStatus = "Up"
		
		# Get the IP address (IPv4 and/or IPv6)
		$results.IPv4Address = $pingCheck.IPv4Address
		$results.IPv6Address = $pingCheck.IPv6Address
		
		# Attempt to get information from the Win32_ComputerSystem class.
		Try
		{
			
			# Get computer system information.
			$computerSystemDomain = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction SilentlyContinue).Domain
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($Error[0].Exception.Message)
		}
		
		# If Win32_ComputerSystem results were obtained, then continue.
		If (!$wmiError)
		{
			# Get the fully qualified domain name.
			$results.FQDN = "$ComputerName.$computerSystemDomain"
			
			# Script was successful.
			$results.ScriptStatus = "OK"
		}
		Else
		{
			
			# Failed to get computer system information.
			$results.ScriptStatus = "Failed - Class: Win32_ComputerSystem - $wmiError"
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
	$pingInfo = $results | Select-Object Computer, PingStatus, IPv4Address, IPv6Address, FQDN, ScriptStatus | ConvertTo-Html -Fragment -PreContent `
		$header -PostContent $footer
	
	# Display the results.
	Write-Output $pingInfo
}
