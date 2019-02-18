<#
	.SYNOPSIS
		Gets scheduled tasks' information from a computer.
	.DESCRIPTION
		This script retrieves TaskName, TaskFolder, IsEnabled, LastRunTime and NextRunTime information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-ScheduledTasks.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-ScheduledTasks
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://www.powershellmagazine.com/2015/04/10/pstip-retrieve-scheduled-tasks-using-schedule-service-comobject
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

	# Gets all the scheduled task folder details.                        
	Function Get-TaskSubFolders 
	{                        
		
		# Get the parameters.
		param (                        
			[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
			$FolderReference
		)

		# Create and array to hold the folder information.
		$results = @() 
		
		# Get the folders.                       
		$folders = $FolderReference.getfolders(1)                        
		
		# If folders exists, then continue.
		If($folders)
		{
		
			# Iterate through each folder.
			ForEach ($folder in $folders)
			{                        
				
				# Add folder to the results.
				$results += $folder                        
				
				# If there is a subfolder, then continue.
				If($folder.getfolders(1))
				{                        
					
					# Run this function again.
					Get-TaskSubFolders -FolderRef $folder                        
				}                        
			}                        
		}
		
		# Return the results.	  
		$results                        
	}     


	# Remove any leading/trailing spaces from $ComputerName.
	$ComputerName = $ComputerName.trim()
	
	# Clear the error variable.
	$error.Clear()

	# Create a custom object to hold scheduled task information.
	$scheduledTaskInfo = [pscustomobject]@{
		Computer = $ComputerName
		TaskName = ""
		TaskFolder = ""
		IsEnabled = ""
		LastRunTime = ""
		NextRunTime = ""
		ScriptStatus = "Failed - Script failed to complete."
	}

	# Create an array to hold all of the scheduled tasks' information.
	$results = @() 	
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to create a schedule service COM object.
		Try
		{
			
			# Create schedule service Com object.
			$scheduleService = New-Object -ComObject ("Schedule.Service")                       
		}
		Catch
		{
			
			# Capture the error.
			$scheduleServiceError = [string]$($error[0].Exception.Message)
		}
	
		# If schedule service COM object creation was successful, then continue.
		If (!$scheduleServiceError)
		{
				 
			# Attempt to connect to the schedule service COM object.     
			Try
			{
				
				# Connect to the schedule service COM object.
				$scheduleService.Connect($ComputerName) 
			}
			Catch
			{
				
				# Capture the error.
				$scheduleServiceError = [string]$($error[0].Exception.Message)
			}					
			
			# If we were able to connect to the schedule service COM object, then continue.
			If (!$scheduleServiceError)
			{
				
				# Get the schedule service root folder.
				$scheduleServiceRootFolder = $scheduleService.GetFolder("\")            
				
				# Get the folders under the root folder.
				$folders = @($scheduleServiceRootFolder)
				
				# Add all subfolders to the folders array.             
				$folders += Get-Tasksubfolders -FolderRef $scheduleServiceRootFolder
				
				# Iterate through each folder.                        
				ForEach ($folder in $folders)
				{
				
					# Get the tasks in each folder.
					$tasks = $folder.gettasks(1)                 
			
					# Iterate through each task.
					ForEach ($task in $tasks)
					{
						
						# Add the scheduled task information to the object.
						$scheduledTaskInfo = [pscustomobject]@{
							Computer = $ComputerName
							TaskName = $task.Name
							TaskFolder = $folder.path
							IsEnabled = $task.enabled
							LastRunTime = $task.LastRunTime
							NextRunTime = $task.NextRunTime
							ScriptStatus = "OK"
						}
						
						# Add the object to the final results.
						$results += $scheduledTaskInfo
					}
				}
			}
			Else
			{
			
				# Failed to connect to the schedule service COM object.
				$scheduledTaskInfo.ScriptStatus = "Failed - Schedule.Service - $scheduleServiceError"
				
				# Update the results.
				$results += $scheduledTaskInfo 
			}
		}
		Else
		{
			
			# Failed to create the schedule service COM object.
			$scheduledTaskInfo.ScriptStatus = "Failed - Schedule.Service - $scheduleServiceError"
			
			# Update the results.
			$results += $scheduledTaskInfo 
		}
	}
	Else
	{
		
		# Failed to connect to the computer.
		$scheduledTaskInfo.ScriptStatus = "Failed - Could not connect to the computer."
		
		# Update the results.
		$results += $scheduledTaskInfo
	}
	
	# General script failure.
	If ($scheduledTaskInfo.ScriptStatus -eq "Failed - Script failed to complete.")
	{
		
		# Update the results.
		$results += $scheduledTaskInfo
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
	$scheduledTasks = $results | Sort TaskFolder | Select-Object Computer, TaskName, TaskFolder, IsEnabled, LastRunTime, NextRunTime, ScriptStatus | `
		ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $scheduledTasks	                
}
