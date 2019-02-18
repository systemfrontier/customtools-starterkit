<#
	.SYNOPSIS
		Gets installed applications' information from a computer.
	.DESCRIPTION
		This script retrieves installed application DisplayName, Version, InstallDate, Publisher, UninstallString, InstallLocation, InstallSource, 
		HelpLink, and EstimatedSizeMB from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-InstalledApps.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-InstalledApps
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service?view=powershell-6
	.LINK
		https://docs.microsoft.com/en-us/dotnet/api/microsoft.win32.registrykey.openremotebasekey?view=netframework-4.7.2
#>

# Sets the output type.
[OutputType('System.Software.Inventory')]

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
	
	# Initialize the variables.
	$svcRemoteRegistryStatusFlag = 0
	$timeout = "00:00:10"
	
	# Set the registry paths to be searched for installed applications.
	$paths = @("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall","SOFTWARE\\Wow6432node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")

	# Create a custom object to hold the installed application information.
	$installedAppsInfo = [pscustomobject]@{
		Computer = $ComputerName
		DisplayName = ""
		Version  = ""
		InstallDate = ""
		Publisher = ""
		UninstallString = ""
		InstallLocation = ""
		InstallSource  = ""
		HelpLink = ""
		EstimatedSizeMB = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the information about the installed applications.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information about the RemoteRegistry service.
		Try
		{
			
			# Get remote registry service information.
			$svcRemoteRegistry = Get-Service -Name "RemoteRegistry" -ComputerName $ComputerName -ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If information about the RemoteRegistry service was obtained, then continue.
		If (!$wmiError)
		{
			
			# If the RemoteRegistry service is not running, then continue.
			If($svcRemoteRegistry.Status -ne "Running")
			{
				
				# Attempt to start the remote registry service.
				($svcRemoteRegistry.Start()) | out-null
				
				# Wait for the service to start.
				$svcRemoteRegistry.WaitForStatus('Running',$timeout)
				
				# Set the flag.
				$svcRemoteRegistryStatusFlag = 1
			}
			
			# If the RemoteRegistry service is running, then continue.
			If ($svcRemoteRegistry.Status -eq "Running")
			{
			
				# Attempt to connect to the registry.
				Try
				{
					
					# Connect to the remote registry.
					$registry=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$ComputerName,'Registry64')
				}
				Catch
				{
					
					# Capture the error.
					$registryError = $true
				}
				
				# If the registry connection was made, then continue.
				If (!$registryError)
				{
				
					# Iterate through both paths in the array.
					ForEach($path in $paths)
					{ 
						
						# Open the registry path.	
						$registryKey=$registry.OpenSubKey($path)
						
						# Contains all the registry subkey names.
						$registrySubKeys=$registryKey.GetSubKeyNames()
						
						# Iterate through each registry subkey.
						ForEach ($registryKey in $registrySubKeys)
						{
							
							# Form the complete registry key path.
							$thisRegistryKey = $Path + "\\" + $registryKey
							
							# Open the registry subkey.
							$thisRegistrySubKey=$registry.OpenSubKey($thisRegistryKey)
							 
							# Get the application name.
							$appDisplayName =  $thisRegistrySubKey.getValue("DisplayName")   
							
							# Only get information from valid application names.
							If ([string]$appDisplayName.length -gt 0)
							{
							
								# Only get applications, not hotfixes, service packs, etc.
								If ($appDisplayName -AND $appDisplayName -notmatch '^Update  for|rollup|^Security Update|^Service Pack|^HotFix')
								{
									
									# Get the application install date.
									$appInstallDate = $thisRegistrySubKey.GetValue('InstallDate')
									
									# If there is an application install date, then continue.
									If ($appInstallDate)
									{
										
										# Attempt to format the application install date.
										Try
										{
											
											# Format the application install date.
											$appInstallDate = [datetime]::ParseExact($appInstallDate, 'yyyyMMdd', $Null)
										}
										Catch
										{
											
											# On error set $appInstallDate to null.
											$appInstallDate = $Null
										}
									} 
									
									# Get the application publisher.
									$appPublisher =  Try{$thisRegistrySubKey.GetValue('Publisher').Trim()} `
										Catch {$thisRegistrySubKey.GetValue('Publisher')}
									
									# Get the application version.
									$appVersion = Try {$thisRegistrySubKey.GetValue('DisplayVersion').TrimEnd(([char[]](32,0)))} `
										Catch {$thisRegistrySubKey.GetValue('DisplayVersion')}
									
									# Get the application uninstall string
									$appUninstallString = Try {$thisRegistrySubKey.GetValue('UninstallString').Trim()} `
										Catch {$thisRegistrySubKey.GetValue('UninstallString')}
									
									# Get the application install location.
									$appInstallLocation = Try {$thisRegistrySubKey.GetValue('InstallLocation').Trim()} `
										Catch {$thisRegistrySubKey.GetValue('InstallLocation')}
									
									# Get the application install source.
									$appInstallSource = Try {$thisRegistrySubKey.GetValue('InstallSource').Trim()} `
										Catch {$thisRegistrySubKey.GetValue('InstallSource')}
									
									# Get the application help link.
									$appHelpLink = Try {$thisRegistrySubKey.GetValue('HelpLink').Trim()} `
										Catch {$thisRegistrySubKey.GetValue('HelpLink')}
									
									# Add application information to the object.
									$installedAppsInfo = [pscustomobject]@{
										Computer = $ComputerName
										DisplayName = $appDisplayName
										Version  = $appVersion
										InstallDate = $appInstallDate
										Publisher = $appPublisher
										UninstallString = $appUninstallString
										InstallLocation = $appInstallLocation
										InstallSource  = $appInstallSource
										HelpLink = $thisRegistrySubKey.GetValue('HelpLink')
										EstimatedSizeMB = [decimal]([math]::Round(($thisRegistrySubKey.GetValue('EstimatedSize')*1024)/1MB,2))
										ScriptStatus = "OK"
									}
								}
								
								# If the application is not already in the results, then continue.
								If ($results -NotContains $installedAppsInfo)
								{
									
									# Update the results.
									$results += $installedAppsInfo
								}
							}
						}
					}	
					
					# If the remote registry service was started here, then continue. 
					If ($svcRemoteRegistryStatusFlag -eq 1)
					{
						
						# Stop the remote registry service to return it to its original state.
						($svcRemoteRegistry.Stop()) | out-null
					}
					
					# Close the registry connection.
					$registry.Close()
				}
				Else
				{
					
					# Failed to open the remote base key in the registry.
					$installedAppsInfo.ScriptStatus = "Failed - Could not open remote base key in registry."
					
					# Update the results.
					$results += $installedAppsInfo
				}
			}
			Else
			{
				
				# Failed to start the remote registry service.
				$installedAppsInfo.ScriptStatus = "Failed - Could not get the installed apps information because the remote registry service `
					failed to start."
				
				# Update the results.
				$results += $installedAppsInfo
			}
		}
		Else
		{
			
			# Failed to get the remote registry service information.
			$installedAppsInfo.ScriptStatus = "Failed - WMI Command: Get-Service -Name 'RemoteRegistry' - $wmiError"
			
			# Update the results.
			$results += $installedAppsInfo
		}   
	}
	Else
	{
		
		# Failed to connect to the computer.
		$installedAppsInfo.ScriptStatus = "Failed - Could not connect to the computer"
		
		# Update the results.
		$results += $installedAppsInfo
	}
	
	# General script failure.
	If ($installedAppsInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $installedAppsInfo
	}
	
	# Create the header for the HTML output of the results. 
	$header = @" 
		<style>
		#tblToolOutput TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-family:verdana; 
		font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; text-align:center; 
		background-color:#39ac6b; color:white; font-weight:bold;} #tblToolOutput TD {border-width: 1px; padding: 3px; border-style: solid; 
		border-color: black;text-align:left;} #tblToolOutput td:nth-child(10){text-align:right;}
		</style>
		<div id=tblToolOutput>
"@

	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$installedApps = $results | Sort DisplayName |Select-Object Computer, DisplayName, Version, InstallDate, Publisher, UninstallString, `
		InstallLocation, InstallSource, HelpLink, EstimatedSizeMB, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $installedApps	
} 
