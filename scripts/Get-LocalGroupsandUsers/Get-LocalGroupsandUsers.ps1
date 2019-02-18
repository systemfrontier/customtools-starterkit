<#
	.SYNOPSIS
		Gets local groups and users from a computer.
	.DESCRIPTION
		This script retrieves LocalGroup, LocalGroupMember and LocalUserAccount information	from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-LocalGroupsAndUsers.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-LocalGroupsAndUsers
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/query-user
	.LINK
		https://docs.microsoft.com/en-us/previous-versions/windows/desktop/usm/win32-userprofile
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-groupuser
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-group
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

	# Create a custom object to hold the local groups and users information.
	$localGroupsAndUsersInfo = [pscustomobject]@{
		Computer = $ComputerName
		LocalGroup = ""
		GroupMember = ""
		LocalUserAccount = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the information about the local groups and users.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_Group class.
		Try
		{
			
			# Get groups information.
			$groups = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True" -ComputerName $ComputerName -ErrorAction Stop).Name
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_Group results were obtained, then continue.
		If (!$wmiError)
		{
			
			# Iterate through the local groups.
			ForEach ($group in $groups)
			{
				
				# Create the query to use.
				$queryA = """Win32_Group.Domain='$ComputerName',Name='$Group'"""
				$query = "SELECT * FROM Win32_GroupUser WHERE GroupComponent = $queryA"
				
				# Attempt to get information from the Win32_GroupUser class.
				Try
				{
					
					# Get group user information.
					$members = Get-WmiObject -ComputerName $ComputerName -ErrorAction Stop -Query $query 
				}
				Catch
				{
					
					# Capture the error.
					$wmiError = [string]$($error[0].Exception.Message)
				}
				
				# If information from Win32_GroupUser was obtained, then continue.
				If (!$wmiError)
				{
					
					# If there are no members in the group, then continue.
					If ($members.Count -eq 0)
					{
					
						# Add the local group and user information to the object.
						$localGroupsAndUsersInfo = [pscustomobject]@{
							Computer = $ComputerName
							LocalGroup = $group
							GroupMember = ""
							LocalUserAccount = ""
							ScriptStatus = "OK"
						}
					
						# Add the object to the final results.
						$results += $localGroupsAndUsersInfo
					}
					Else
					{
						# Iterate through the local group members.
						ForEach ($member in $members)
						{
							
							# Retrieve domain and user information.
							$partComponentA = $member.PartComponent.split("=")
							$partComponentB = $partComponentA[1].split("""")
							$domain = $partComponentB[1]
							$partComponentB = $partComponentA[2].split("""")
							$user = $partComponentB[1]
							$groupMember = "$domain\$user"
							
							# If the domain name is the same as the computer name, then the account is local.
							If ($domain -eq $ComputerName)
							{
								
								# Account is a local account.
								$localUserAccount = "Yes"
							}
							Else
							{
								
								# Account is a domain account.
								$localUserAccount = ""
							}
							
							# Add the local group and user information to the object.
							$localGroupsAndUsersInfo = [pscustomobject]@{
								Computer = $ComputerName
								LocalGroup = $group
								GroupMember = $groupMember
								LocalUserAccount = $localUserAccount
								ScriptStatus = "OK"
							}
							
							# Add the object to the final results.
							$results += $localGroupsAndUsersInfo
						} 
					}
				}
				Else
				{
					
					# Failed to get group user information.
					$localGroupsAndUsersInfo.ScriptStatus = "Failed - WMI class: Win32_GroupUser - $wmiError"
					
					# Update the results.
					$results += $localGroupsAndUsersInfo
				}
			}
		}
		Else
		{
			
			# Failed to get group information.
			$localGroupsAndUsersInfo.ScriptStatus = "Failed - WMI class: Win32_Group - $wmiError"
			
			# Update the results.
			$results += $localGroupsAndUsersInfo
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$localGroupsAndUsersInfo.ScriptStatus = "Failed - Could not connect to the computer"
		
		# Update the results.
		$results += $localGroupsAndUsersInfo
	}
	
	# General script failure.
	If ($localGroupsAndUsersInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $localGroupsAndUsersInfo
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
	$groupMembers = $results | Select-Object Computer, LocalGroup, GroupMember, LocalUserAccount, ScriptStatus | ConvertTo-Html -Fragment `
		-PreContent $header -PostContent $footer

	# Display the results.
	Write-Output $groupMembers
}
