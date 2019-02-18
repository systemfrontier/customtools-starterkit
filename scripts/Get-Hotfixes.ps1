<#
	.SYNOPSIS
		Gets hotfixes' information from a computer.
	.DESCRIPTION
		This script retrieves HotFixID, Description, InstalledBy and InstalledOn information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-Hotfixes.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-Hotfixes
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-quickfixengineering
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

	# Create a custom object to hold the hotfix information.
	$hotfixInfo = [pscustomobject]@{
		Computer = $ComputerName
		HotFixID = ""
		HotFixDescription = ""
		HotFixInstalledBy = ""
		HotFixInstalledOn = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the hotfixes' information.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_QuickFixEngineering class.
		Try
		{
			
			# Get hotfixes information.
			$hotfixes = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_QuickFixEngineering results were obtained, then continue.
		If (!$wmiError)
		{
		
			# Iterate through each hotfix.
			ForEach($hotfix in $hotfixes)
			{
			
				# Get the hotfix installed on date.
				$hotfixInstalledOn = $hotfix.InstalledOn.ToString("MM/dd/yyyy")
				
				# Add the hotfix information to the object.
				$hotfixInfo = [pscustomobject]@{
					Computer = $ComputerName
					HotFixID = $hotfix.HotFixID
					HotFixDescription = $hotfix.Description
					HotFixInstalledBy = $hotfix.InstalledBy
					HotFixInstalledOn = $hotfixInstalledOn
					ScriptStatus = "OK"
				}
				
				# Add the object to the final results.
				$results += $hotfixInfo
			}
		}
		Else
		{
			
			# Failed to get hotfixes information.
			$hotfixInfo.ScriptStatus = "Failed - WMI Class: Win32_QuickFixEngineering - $wmiError"
			
			# Update the results.
			$results += $hotfixInfo
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$hotfixInfo.ScriptStatus = "Failed - Could not connect to the computer"
		
		# Update the results.
		$results += $hotfixInfo
	}
	
	# General script failure.
	If ($hotfixInfo.ScriptStatus -eq "Failed - Script failed to complete.") 
	{
		
		# Update the results.
		$results += $hotfixInfo
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
	$hotfixes = $results | Sort HotFixID | Select-Object Computer, HotFixID, HotFixDescription, HotFixInstalledBy, HotFixInstalledOn, ScriptStatus | ConvertTo-Html `
		-Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $hotfixes
}
