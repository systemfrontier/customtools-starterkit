<#
	.SYNOPSIS
		Gets operating system information from a computer.
	.DESCRIPTION
		This script retrieves OSName, OSServicePack, OSBitVersion, Domain, LicenseStatus, LicenseName, LicenseDescription, 
		LicenseKeyServer, LicenseGenuineStatus, LicenseID, and LicenseFamily information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-OSInfo.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-OSInfo
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-computersystem
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-operatingsystem
	.LINK		
		https://docs.microsoft.com/en-us/previous-versions/windows/desktop/sppwmi/softwarelicensingproduct
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
	
	# Create a custom object to hold the operating system information.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		OSName = ""
		OSServicePack  = ""
		OSBitVersion = ""
		Domain = ""
		LicenseStatus = ""
		LicenseName = ""
		LicenseDescription = ""
		LicenseKeyServer  = ""
		LicenseGenuineStatus = ""
		LicenseID = ""
		LicenseFamily = ""
		ScriptStatus = "Failed - Script failed to complete."
	}
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_ComputerSystem class.
		Try
		{
			
			# Get computer system information.
			$computerSystem = Get-WMIObject -Class Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_ComputerSystem results were obtained, then continue.
		If (!$wmiError)
		{
			
			# Get the domain name.
			$results.Domain = $computerSystem.Domain

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
			
				# Get the operating system name, service pack, and OS bit version (32 or 64).
				$results.OSName = $operatingSystem.Caption
				$results.OSServicePack = $operatingSystem.CSDVersion
				$results.OSBitVersion = $operatingSystem.OSArchitecture
				
				# Attempt to get information from the SoftwareLicensingProduct class.
				Try
				{
					
					# Get operating system license information.
					$softwareLicense = Get-WmiObject -Class SoftwareLicensingProduct -ComputerName $ComputerName -ErrorAction Stop | `
						Where-Object { $_.PartialProductKey -and $_.Name -like "*Windows*"}
				}
				Catch
				{
					
					# Capture the error.
					$wmiError = [string]$($error[0].Exception.Message)
				}
				
				# If SoftwareLicensingProduct results were obtained, then continue.
				If (!$wmiError)
				{
				
					# Get the operating system license information.
					$results.LicenseDescription = $softwareLicense.Description
					$results.LicenseKeyServer = $softwareLicense.DiscoveredKeyManagementServiceMachineName
					$results.LicenseGenuineStatus = $softwareLicense.GenuineStatus
					$results.LicenseID = $softwareLicense.ID
					$results.LicenseFamily = $softwareLicense.LicenseFamily
					$results.LicenseName = $softwareLicense.Name
					Switch($softwareLicense.LicenseStatus){
						0 {$results.LicenseStatus = 'Unlicensed'; Break}
						1 {$results.LicenseStatus = 'Licensed'; Break}
						2 {$results.LicenseStatus = 'OOBGrace'; Break}
						3 {$results.LicenseStatus = 'OOTGrace'; Break}
						4 {$results.LicenseStatus = 'NonGenuineGrace'; Break}
						5 {$results.LicenseStatus = 'Notification'; Break}
						6 {$results.LicenseStatus = 'ExtendedGrace'; Break}
					}
					
					# Results are good.
					$results.ScriptStatus = "OK"
					
				}
				Else
				{
					
					# Failed to get operating system license information.
					$results.ScriptStatus = "Failed - WMI Class: SoftwareLicensingProduct - $wmiError"
				}
			}
			Else
			{
				
				# Failed to get computer system information.
				$results.ScriptStatus = "Failed - WMI Class: Win32_ComputerSystem - $wmiError"
			}	
		}
		Else
		{
			
			# Failed to get operating sytem information.
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
	$operatingSystemInfo = $results | Select-Object Computer, OSName, OSServicePack, OSBitVersion, Domain, LicenseStatus, LicenseName, `
		LicenseDescription, LicenseKeyServer, LicenseGenuineStatus, LicenseID, LicenseFamily, ScriptStatus | ConvertTo-Html -Fragment `
		-PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $operatingSystemInfo	
}
