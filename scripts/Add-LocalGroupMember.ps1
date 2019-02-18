<#
	.SYNOPSIS
		Adds a user or group to a local group on a computer.
	.DESCRIPTION
		A user or group account can be added to a local group on a target computer with this script.
	.PARAMETER ComputerName
		The name of the target computer.
	.PARAMETER LocalGroupName
		The name of the local group on the target computer.
	.PARAMETER AccountName
		The name of the account to add to the local group on the target computer.
	.EXAMPLE
		.\Add-LocalGroupMember.ps1 -ComputerName "COMP01" -LocalGroupName "Backup Operators" -AccountName "MYDOMAIN\xyzdomainuser"
	.EXAMPLE
		.\Add-LocalGroupMember.ps1 -ComputerName "COMP01" -LocalGroupName "Administrators" -AccountName "xyzdomainuser@MYDOMAIN"
	.EXAMPLE
		.\Add-LocalGroupMember.ps1 -ComputerName "COMP01" -LocalGroupName "Administrators" -AccountName "COMP01\xyzlocaluser"
	.EXAMPLE
		.\Add-LocalGroupMember.ps1 -ComputerName "COMP01" -LocalGroupName "Administrators" -AccountName "xyzlocaluser"		
	.NOTES
		Name:		Add-LocalGroupMember
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-group
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-useraccount
	.LINK
		https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-aduser?view=winserver2012-ps
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/ADSI/adsi-winnt-provider
#>

# Provides additional functionality.
[Cmdletbinding()]

# Get the parameters.
Param( 
	[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
	[String]$ComputerName,
	[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
	[String]$LocalGroupName,
	[Parameter(ValueFromPipeline=$False, Position=2, Mandatory=$true)]
	[String]$AccountName
)

Process
{  

	# Separates the account name into 2 parts: domain and id.
	Function Get-AccountNameParts {
		
		# Get the parameters.
		Param(
			[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
			[String]$ComputerName,
			[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
			[String]$AccountName
		)

		# Create a hashtable to hold the values.
		[hashtable]$results = @{}
		
		# Determine the account name format.
		If ($AccountName.contains("\") -OR $AccountName.contains("@"))
		{
			
			# If the account name contains a slash, then continue.
			If ($AccountName.contains("\"))
			{
			
				# Account name has the format of domain\id.  Split the domain from the id.
				$splitAccountName = $AccountName.split("\")
			
				# Get the domain name.
				$results.Domain = [string]$splitAccountName[0].trim()
				
				# Get the id (user or group name).
				$results.ID = [string]$splitAccountName[1].trim()
			}
			Else
			{
			
				# The account name is formatted as account@domain.  Split the domain from the id.
				$splitAccountName = $AccountName.split("@")
				
				# Get the domain name.
				$domain = [string]$splitAccountName[1].trim()
				
				# Get the id (user or group name).
				$results.ID = [string]$splitAccountName[0].trim()
				
				# Get the fully qualified domain parts.
				$splitDomain = $domain.split(".")
				
				# Get only the first section of the fully qualified domain name.
				$results.Domain = $splitDomain[0]
			}
		}
		Else
		{
			
			# Account name only has the id portion. Domain will equal the computer name in this case.
			$results.Domain = $ComputerName
			
			# The ID will equal the account name.
			$results.ID = $AccountName
		}
		
		# Return the results.
		$results		
	}
	
	# Remove any leading/trailing spaces from $ComputerName, $LocalGroupName and $AccountName.
	$ComputerName = $ComputerName.trim()
	$LocalGroupName = $LocalGroupName.trim()
	$AccountName = $AccountName.trim()
	
	# Initialize the variables.
	$error.Clear()
	$addError = $adsiError = $getUserError = ""
	$domainNameIsComputerName = $isValidAccount = $isLocalGroupMember = $false
	
	# Create a custom object to hold the add local group member results.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		LocalGroupName = $LocalGroupName
		AccountName = $AccountName
		Status = "Failed - Script failed to complete."
	}
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the local group.
		Try
		{
			
			# Connect to the local computer and group. 
			$localGroupObject=[ADSI]"WinNT://$ComputerName/$LocalGroupName,group"
		}
		Catch
		{
			
			# Capture the error.
			$adsiError = [string]$($error[0].Exception.Message)
		}
		
		# If ADSI results were obtained, then continue.
		If ([String]$localGroupObject.Path.length -gt 0)
		{	

			# Get the parts out of the account name submitted.
			$accountNameParts = Get-AccountNameParts -ComputerName $ComputerName -AccountName $AccountName
			$domain = $accountNameParts.Domain
			$id = $accountNameParts.ID
			
			# Attempt to get information from the account.
			Try
			{
				
				# Connect to the account object
				$accountObject = [ADSI]"WinNT://$domain/$id"
			}
			Catch
			{
				
				# Capture the error.
				$adsiError = [string]$($error[0].Exception.Message)
			}
			
			
			# If ADSI results were obtained, then continue.
			If ([String]$accountObject.Path.length -gt 0)
			{

				# Attempt to add the account to the local group.
				Try
				{
				
					# Add the account.
					$localGroupObject.Add($accountObject.Path)
				}
				Catch
				{
					
					# Capture the error.
					$addError = [string]$($error[0].Exception.Message)
				}
				
				# If the account was added to the group, then continue.
				If (!$addError)
				{
				
					# The account was added to the local group.
					$results.Status = "Success - Account was added to local group."	
				}
				ElseIf ($addError.Contains("already a member of the group") -eq $true)
				{
			
					# Account is already a member of the local group.
					$results.Status = "Success - Account was already a member of the local group."
				}
				Else
				{
				
					# The account was not added to the local group.
					$results.Status = "Failed - Unable to add the account to the local group. $addError"
				}
			}
			Else
			{ 
				
				# The account name does not exist or is invalid.
				$results.Status = "Failed - Account name does not seem to exist.  Please check the account name."
			}
		}
		Else
		{
			
			If ($adsiError)
			{
			
				# Failed to add the account to the local group.
				$results.Status = "Failed - Account not added to local group.  $adsiError"
			}
			Else
			{
				
				# Failed to add the account to the local group.
				$results.Status = "Failed - Account not added to local group.  Please check the local group name."
			}
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$results.Status = "Failed - Could not connect to the computer."
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
	$addAccountToLocalGroup = $results | Select-Object Computer, LocalGroupName, AccountName, Status | ConvertTo-Html -Fragment -PreContent $header `
		-PostContent $footer
	
	# Display the results.
	Write-Output $addAccountToLocalGroup	
}
