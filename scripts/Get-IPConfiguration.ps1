<#
	.SYNOPSIS
		Gets IP configuration information from a computer.
	.DESCRIPTION
		This script retrieves NetworkAdapter, IPAddress, SubnetMask, Gateway, DNSServers, WINSPrimaryServer, WINSSecondaryServer, IPEnabled, and
		DHCPEnabled network configuration information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-IPConfiguration.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-IPConfiguration
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-networkadapterconfiguration
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

	# Create a custom object to hold each network adapter's information.
	$ipConfigInfo = [pscustomobject]@{
		Computer = $ComputerName
		NetworkAdapter = ""
		IPAddress = ""
		SubnetMask = ""
		Gateway = ""
		DNSServers = ""
		WINSPrimaryServer = ""
		WINSSecondaryServer = ""
		IPEnabled = ""
		DHCPEnabled = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the information about the network adapters.
	$results = @() 	

	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_NetworkAdapterConfiguration class.
		Try
		{
			
			# Get the network adapter configuration information.
			$networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=TRUE' -ComputerName `
				$ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If network adapter information was obtained, then continue.
		If (!$wmiError){
			
			# Iterate through each network adapter.
			ForEach ($networkAdapter in $networkAdapters)
			{
			
					# Add each network adapter's configuration information to the object.
					$ipConfigInfo = [pscustomobject]@{
						Computer = $ComputerName
						NetworkAdapter = $networkAdapter.Description
						IPAddress = $networkAdapter.IPAddress[0]
						SubnetMask = $networkAdapter.IPSubnet[0]
						Gateway = [String]$networkAdapter.DefaultIPGateway
						DNSServers = [String]$networkAdapter.DNSServerSearchOrder
						WINSPrimaryServer = $networkAdapter.WINSPrimaryServer
						WINSSecondaryServer = $networkAdapter.WINSSecondaryServer
						IPEnabled = $networkAdapter.IPEnabled
						DHCPEnabled = $networkAdapter.DHCPEnabled
						ScriptStatus = "OK"
					}
					
					# Add the object to the final results.
					$results += $ipConfigInfo
			}
		}
		Else
		{
			
			# Failed to get network adapter configuration information.
			$ipConfigInfo.ScriptStatus = "Failed - WMI Class: Win32_NetworkAdapterConfiguration - $wmiError"
			
			# Update the results.
			$results += $ipConfigInfo
		}   
	}
	Else
	{
		
		# Failed to connect to the computer.
		$ipConfigInfo.ScriptStatus = "Failed - Could not connect to computer."
		
		# Update the results.
		$results += $ipConfigInfo
	}
	
	# General script failure.
	If ($ipConfigInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $ipConfigInfo
	}
	
	# Create the header for the HTML output of the results. The "@ at the end must be leftmost on the line or powershell won't recognize it properly.
	$header = @" 
			<style>
			#tblToolOutput TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-family:verdana; 
			font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; text-align:center; 
			background-color:#39ac6b; color:white; font-weight:bold;} #tblToolOutput TD {border-width: 1px; padding: 3px; border-style: solid; 
			border-color: black;text-align:left;} #tblToolOutput TH:nth-child(6){width:5px;} #tblToolOutput TD:nth-child(6){width:5px;white-space: 
			pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;}
			</style>
			<div id=tblToolOutput>
"@

	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$ipConfig = $results | Select-Object Computer, NetworkAdapter, IPAddress, SubnetMask, Gateway, DNSServers, WINSPrimaryServer, `
		WINSSecondaryServer, IPEnabled, DHCPEnabled, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $ipConfig	
}
