<#
	.SYNOPSIS
		Gets logged on users' information from a computer.
	.DESCRIPTION
		This script retrieves logged on UserName, LastLogonTime, Status, ProfileLoaded, Session, ID, State, IdleTime and LogonTime information
		from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-LoggedOnUsers.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-LoggedOnUsers
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/query-user
	.LINK
		https://docs.microsoft.com/en-us/previous-versions/windows/desktop/usm/win32-userprofile
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

	# Gathers logged on user information from the quser command.
	Function Get-LoggedOnUsers
	{
		
		# Get the parameters.
		param(
			[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)] 
			[String]$ComputerName,
			[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
			[String]$UserName
		)
		
		# Initialize the variables
		$quserError = $false
		
		# Create an array to hold all of the information about the logged on users.
		$results = @()
		
		# Attempt to get the logged on users information via the quser command.
		Try
		{
			# Set error action to continue os quser command will not display quser results for users not found.
			$errorAction = "Continue"
			
			# Get quser (query user) results.
			$queryQuser = (quser $UserName /server:$ComputerName) 2>&1
			
			# Set error action back to stop.
			$errorAction = "Stop"	
		}
		Catch
		{
			
			# Query user attempt failed.
			$quserError = $true
		}
		
		# If the quser query returned valid results, then continue.
		If ($quserError -eq $false -AND $queryQuser[1].length -gt 0)
		{

			# Reformat the quser results to comma-delimited.
			$queryQuser = $queryQuser -replace '\s{2,}', ',' 
			
			# Get user information.
			$userResults = $queryQuser[1].split(",")
						
			# The quser output is misaligned sometimes, so correcting for that and setting values.
			If($userResults[1] -match "^[\d\.]+$")
			{

				# Set values with user information.
				$session = ""
				$id = $userResults[1]
				$state = $userResults[2]
				$idleTime = $userResults[3]
				$logonTime = $userResults[4]
			}
			Else
			{

				# Set values with user information.
				$session = $userResults[1]
				$id = $userResults[2]
				$state = $userResults[3]
				$idleTime = $userResults[4]
				$logonTime = $userResults[5]
			}
			
			# Add user information to the object.
			$results = [pscustomobject]@{
				Computer = $ComputerName
				UserName =  $UserName
				Session = $session
				ID = $id
				State = $state
				IdleTime = $idleTime
				LogonTime = $logonTime
			}
		}
		Else
		{
			
			# If no quser query valid results, set results to FALSE.
			$results = $false
		}
		
		# Return the results.
		$results
	}

	# Remove any leading/trailing spaces from $ComputerName.
	$ComputerName = $ComputerName.trim()
	
	# Clear the error variable.
	$error.Clear()

	# Create a custom object to hold the logged on user information.
	$loggedOnUserInfo = [pscustomobject]@{
		Computer = $ComputerName
		UserName = ""
		LastLogonTime = ""
		ProfileLoaded = ""
		Status = ""
		Session = ""
		ID = ""
		State = ""
		IdleTime = ""
		LogonTime =""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the information about the logged on users.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_UserProfile class.
		Try
		{
			
			# Get user profile information.
			$users = Get-WmiObject -Class Win32_UserProfile -Filter "Special='False'" -ComputerName $ComputerName -ErrorAction Stop | `
				select @{Name='UserName';Expression={Split-Path $_.LocalPath -Leaf}}, LocalPath, Loaded, Status, @{Name='LastUsed';`
				Expression={$_.ConvertToDateTime($_.LastUseTime)}}, PSComputerName | sort LastUsed -Descending
		}
		Catch
		{
			
			# Capture the error.
			$wmiError = [string]$($error[0].Exception.Message)
		}
		
		# If Win32_UserProfile results were obtained, then continue.
		If (!$wmiError)
		{
		
			# Iterate through the users from the Win32_UserProfile class.
			ForEach($user in $users)
			{
			
				# Get the logged on users from the quser command via the Get-LoggedOnUsers function.
				$loggedOnUser = Get-LoggedOnUsers -ComputerName $ComputerName -UserName $user.UserName
				
				# If user is logged on, then continue.
				If($loggedOnUser)
				{
					# Set values with user information.
					$session = $loggedOnUser.Session
					$id = $loggedOnUser.ID
					$state = $loggedOnUser.State
					$idleTime = $loggedOnUser.IdleTime
					$logonTime = $loggedOnUser.LogonTime
				}
				Else
				{ 
					# Set values to nothing.
					$session = ""
					$id = ""
					$state = ""
					$idleTime = ""
					$logonTime = ""
				}
				
				Switch ($user.Status)
				{
					1 {$status = "Temporary Profile"}
					2 {$status = "Roaming Profile"}
					4 {$status = "Mandatory Profile"}
					8 {$status = "Corrupt Profile"}
					Default {$status = ""}
				}
				
				# Add the logged on user information to the object.
				$loggedOnUserInfo = [pscustomobject]@{
					Computer = $ComputerName
					UserName = $user.UserName
					LastLogonTime = $user.LastUsed
					ProfileLoaded = $user.Loaded
					Status = $status
					Session = $session
					ID = $id
					State = $state
					IdleTime = $idleTime
					LogonTime = $loggedOnUser.LogonTime
					ScriptStatus = "OK"
				}
				
				# Add the object to the final results.
				$results += $loggedOnUserInfo
			}
		}
		Else
		{
			
			# Failed to get user profile information.
			$loggedOnUserInfo.ScriptStatus = "Failed - WMI Class: Win32_UserProfile - $wmiError"
			
			# Update the results.
			$results += $loggedOnUserInfo
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$loggedOnUserInfo.ScriptStatus = "Failed - Could not connect to computer."
		
		# Update the results.
		$results += $loggedOnUserInfo
	}
	
	# General script failure.
	If ($loggedOnUserInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $loggedOnUserInfo
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
	$loggedOnUsers = $results | Sort State -Descending | Select-Object Computer, UserName, LastLogonTime, ProfileLoaded, Status, Session, ID, State, IdleTime, `
	LogonTime, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer

	# Display the results.
	Write-Output $loggedOnUsers	
}
