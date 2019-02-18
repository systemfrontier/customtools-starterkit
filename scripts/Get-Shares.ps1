<#
	.SYNOPSIS
		Gets shares' information from a computer.
	.DESCRIPTION
		This script retrieves ShareName, Account, SharePermissions and NTFSPermissions information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-Shares.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-Shares
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/previous-versions/windows/desktop/secrcw32prov/win32-logicalsharesecuritysetting
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-useraccount
	.LINK		
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-share
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

	# Function to get the share permissions.
	Function Get-SharePermissions
	{
		
		# Get the parameters.
		Param( 
			[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
			[String]$ComputerName,
			[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
			[String]$ShareName,
			[Parameter(ValueFromPipeline=$False, Position=2, Mandatory=$true)]
			[String]$Path
		)

		# Clear the error variable.
		$error.Clear()
		
		# Create an array to hold all of the shares' information.
		$results = @()

		# Attempt to get share security settings for the share name.
		Try
		{
			
			# Get share security settings information.
			$shareSecuritySettings = Get-WmiObject Win32_LogicalShareSecuritySetting -Filter "name='$ShareName'" -ComputerName $ComputerName `
				-ErrorAction Stop
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = $($error[0].Exception.Message)
		}
		
		# If there were share security setting results, then continue.
		If (!$wmiError)
		{
		
			# Attempt to get the share ACLs.
			Try
			{
				
				# Get the share ACLs.
				$shareAcls = $shareSecuritySettings.GetSecurityDescriptor().Descriptor.DACL
			}
			Catch
			{
				
				# Capture the error.
				$wmiError = "Failed - Could not get share ACLs."
			}
				
			# If there were share ACL results, then continue.	
			If (!$wmiError)
			{
				
				# Iterate through each ACL.
				ForEach ($shareAcl in $shareAcls)
				{
				
					# Get the share trustee name.
					$shareTrusteeName = $shareAcl.Trustee.Name
					
					# If there was not a share trustee name, then use the trustee SIDString value.
					If (!$shareTrusteeName)
					{ 
						
						# Get the SID.
						$shareTrusteeName = $shareAcl.Trustee.SIDString
					}
					
					# Get the share trustee domain.
					$shareDomain = $shareAcl.Trustee.Domain
					
					# Get the share permissions.
					$shareAccessMask = $shareAcl.AccessMask
					Switch ($shareAccessMask)
					{
						2032127 { $sharePermissions = "Full Control" }
						1245631 { $sharePermissions = "Change" }
						1179817 { $sharePermissions = "Read" }
						default {  $sharePermissions = "AccessMask: $shareAccessMask"}
					}
					
					# If there is not a share trustee domain (as is the case for the Everyone group), then change the shareAccount.
					If ($shareDomain)
					{
						
						# Include the share domain.
						$shareAccount = "$shareDomain\$shareTrusteeName"
					}
					Else
					{
						
						# Omit the share domain.
						$shareAccount = "$shareTrusteeName"
					}
					
					# Convert the account name to an upper case string value for consistency.
					$shareAccount = $shareAccount.toString().ToUpper()
					
					# Add share information to the object.
					$shareInfo = [PSCustomObject]@{
						Computer = $ComputerName
						ShareName = $ShareName
						Account = $shareAccount
						SharePermissions = $sharePermissions
						NTFSPermissions = ""
						Path = $Path
						ScriptStatus = "OK"
					} 
					
					# Add the object to the final results.
					$results += $shareInfo
					
				}
			}
		}
		Else
		{
			
			# Failed to get share security settings information.
			$results = $false
		}
		
		# Return the results.
		$results
	}
	

	# Function to get the NTFS permissions of the share path.
	Function Get-NTFSPermissions
	{
		
		# Get the parameters.
		Param( 
			[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
			[String]$ComputerName,
			[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
			[String]$ShareName,
			[Parameter(ValueFromPipeline=$False, Position=2, Mandatory=$true)]
			[String]$Path
		)

		# Replace the colon in the path with a $.
		$adjustedPath = $Path.Replace(":","$")
		
		# Get the new adjusted path (used to get NTFS permissions).
		$sharePath = "\\$ComputerName\$adjustedPath"

		# Clear the error variable.
		$error.Clear()
		
		# Create an array to hold all of the shares' information.
		$results = @()
		
		# Create an array to hold the share's ACL information.
		$resultsACL = @()
			
		# Attempt to get ACLs for the path.	
		Try
		{
			
			# Get ACLs.
			$ntfsACLs = Get-Acl $sharePath
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = $($Error[0].Exception.Message)
		}
		
		# If NTFS ACLs were obtained, then continue.
		If (!$wmiError)
		{
		
			# Iterate through each ACL access.
			ForEach ($ntfsACL in $ntfsACLs.Access)
			{
				
				# Add the ACL to the results.
				$resultsACL += $ntfsACL
			}
			
			# Get each account that has permissions.
			$accounts = $resultsACL.IdentityReference | ForEach-Object { $_} | Select-Object -Unique

			# Attempt to get information from the Win32_UserAccount class (used below to remedy SID issues).
			Try
			{
				
				# Get user account information.
				$users = Get-wmiobject Win32_UserAccount -filter "LocalAccount=TRUE" -computer $ComputerName
			}
			Catch
			{
				
				# Do nothing. Either account was not a SID or otherwise invalid.
			}
			
			# Iterate through each account.
			ForEach ($account in $accounts)
			{
					
				# This contains the permissions.	
				$permissionACL = ""
				
				# Used to flag if we need to append a permission later (by adding a comma before next permission is added).
				$commaFlag = 0
				
				# Iterate through each ACL access array.
				ForEach ($accountAccess in $ntfsACLs.Access)
				{
				
					# Get the file system rights value.
					$rights = $accountAccess.FileSystemRights
					
					# If the account has a match with the iterated access identity value.
					If ($account -eq $accountAccess.IdentityReference)
					{
						
						# If the permission is not already accounted for, then continue. 
						# In some cases duplicate permissions are found, but are not needed here.
						If ($permissionACL -NotContains $rights)
						{ 
						
							# Need to translate some rights that only return a number.
							Switch ($rights)
							{
								2147483648 { $rights = "GenericRead" }
								1073741824 { $rights = "GenericWrite" }
								536870912 { $rights = "GenericExecute" }
								268435456 { $rights = "GenericAll" }
								-1610612736 { $rights = "ReadAndExecuteExtended" }
								1180063 { $rights = "Read, Write" }
								1179817 { $rights = "ReadAndExecute" }
								1245631 { $rights = "ReadAndExecute, Modify, Write" }
								1180095 { $rights = "ReadAndExecute, Write" }
								default { $rights = $rights }
							}
						
							# If comma is needed to append a permission to the existing rights.
							If ($commaFlag -eq 1)
							{
								
								# Include a comma with the rights.
								$permissionACL = ("$permissionACL,$rights")
							}
							Else
							{
								
								# Do not include a comma with the rights, but set the comma flag for next time.
								$permissionACL = $rights
								$commaFlag = 1
							}
						}
					}
				}
				
				# If the users information was obtained, then continue.
				If ($users)
				{
				
					# Iterate through the local user accounts and try to find a SID match.
					ForEach ($user in $users)
					{
						
						# If $account is a SID instead of a proper name, get the user name.
						If ($account -eq $user.SID)
						{
							
							# Get the user name.
							$account = $user.Caption
						}
					}
				}

				# Convert the account name to an upper case string value for consistency.
				$uppercaseAccount = $account.toString().ToUpper()
				
				# Add NTFS permissions information to the object.
				$ntfsPermissions = [PSCustomObject]@{
					Computer = $ComputerName
					ShareName = $ShareName
					Account = $uppercaseAccount
					SharePermissions = ""
					NTFSPermissions = $permissionACL
					Path = $Path
					ScriptStatus = "OK"
				} 
				
				# Add the object to the final results.
				$results += $ntfsPermissions					
			}
		}
		Else
		{
			
			# Failed to get ACLs.
			$results = $false
		}		
		
		# Return the results.
		$results
	}
	
	# Remove any leading/trailing spaces from $ComputerName.
	$ComputerName = $ComputerName.trim()
	
	# Clear the error variable.
	$error.Clear()

	# Create a custom object to hold the share information.
	$shareInfo = [pscustomobject]@{
		Computer = $ComputerName
		ShareName = ""
		Account = ""
		SharePermissions = ""
		NTFSPermissions = ""
		Path = ""
		ScriptStatus = "Failed - Script failed to complete"
	}

	# Create arrays to hold all of the shares' information.
	$results = @() 
	$resultsTemp = @()
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_Share class.
		Try
		{
			
			# Get share information.
			$shares = Get-WmiObject -Class Win32_Share -ComputerName $ComputerName -ErrorAction Stop                     
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
	
		# If Win32_Service results were obtained, then continue.
		If (!$wmiError)
		{
		
			# Iterate through each share
			ForEach ($share in $shares)
			{
			
				# Get the share name and share path.
				$ShareName = $share.Name
				$Path = $share.Path

				# Only get permissions if a path exists.	
				If ($Path)
				{
				
					# get share permissions
					$sharePermissions = Get-SharePermissions -ComputerName $ComputerName -ShareName $ShareName -Path $Path
				
					# Get ntfs permissions.
					$ntfsPermissions = Get-NTFSPermissions -ComputerName $ComputerName -ShareName $ShareName -Path $Path
					
					# Add the share and ntfs permissoin results to the temporary results.
					$resultsTemp += $sharePermissions
					$resultsTemp += $ntfsPermissions
				}
			}
			
			# Get a count of the objects in the temporary results.
			$resultsTempCount = $resultsTemp.Count
			
			# Iterate through the temporary results.  Goal is to combine share and NTFS results with common account and share names. 
			For ($i = 0; $i -le $resultsTempCount; $i++)
			{
				
				# Flag is used to determine if there was a match.
				$iFlag = -1
				
				# Iterate through the temporary results to find matches.
				For ($j = 0; $j -le $resultsTempCount; $j++)
				{
					
					# Only proceed if the array item number is not the same.
					If ($i -ne $j)
					{
					
						# If the share and account names match, then continue.
						If ($resultsTemp[$i].ShareName -eq $resultsTemp[$j].ShareName -AND $resultsTemp[$i].Account -eq $resultsTemp[$j].Account)
						{
							
							# If NTFS permissions exist, then continue.
							If ($resultsTemp[$i].NTFSPermissions.length -eq 0)
							{
							
								# Modify the array item to include NTFS permissions where they may be missing.
								$resultsTemp[$i].NTFSPermissions = $resultsTemp[$j].NTFSPermissions
								
								# Set the flag to know which array item to add later.
								$iFlag = $i
								
							} 
							Else
							{
								
								# No NTFS permissions exist.
								$resultsTemp[$j].NTFSPermissions = $resultsTemp[$i].NTFSPermissions
								$iFlag = $j
							}
						}
					}				
				}
				
				# If a share account matched an NTFS account within the same share name, then add that modified entry to the final results.
				If ($iFlag -ne -1){
					
					# Add combined item to final results.
					$results += $resultsTemp[$iFlag]
				}
				Else{
				
					# If the was no match, then just add the item to the final results.
					$results += $resultsTemp[$i]
				}
			}
			
			# Remove duplicates from the results
			$results = $results | Select * -Unique
		}
		Else
		{
			
			# Failed to get share information.
			$shareInfo.ScriptStatus = "Failed - WMI Class: Win32_Share - $wmiError"
			
			# Update the results.
			$results += $shareInfo
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$shareInfo.ScriptStatus = "Failed - Could not connect to computer."
		
		# Update the results.
		$results += $shareInfo
	}
	
	# General script failure.
	If ($shareInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $shareInfo
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
	$shares = $results | Sort ShareName, Account | Select-Object Computer, ShareName, Account, SharePermissions, NTFSPermissions, Path, `
		ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $shares
}
