<#
	.SYNOPSIS
		Gets hardware information from a computer.
	.DESCRIPTION
		This script retrieves Manufacturer, Model, VM, Memory, CPU, MaxClockSpeed, CPUBits, NumberOfCores, NumberOfLogicalProcessors, SerialNumber
		and BIOSVersion information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-HardwareInfo.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-HardwareInfo
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-computersystem
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-processor
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-bios
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

	# Create a custom object to hold the hardware information.
	$results = [pscustomobject]@{
		Computer = $ComputerName
		Manufacturer = ""
		Model = ""
		VM = ""
		Memory = ""
		CPU = ""
		MaxClockSpeed = ""
		CPUBits = ""
		NumberOfCores = ""
		NumberOfLogicalProcessors = ""
		SerialNumber = ""
		BIOSVersion = ""
		ScriptStatus = "Failed - Script failed to complete."
	}
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Attempt to get information from the Win32_ComputerSystem class.
		Try
		{
			
			# Get the computer system information.
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
		
			# Get the manufacturer.
			$results.Manufacturer = [string]$computerSystem.Manufacturer
			
			# Get the model.
			$model =  [string]$computerSystem.Model
			$results.Model = $Model
			
			# Determine if the computer is a VM or not.
			If ($model -eq "Virtual Machine" -OR $model -eq "VMware Virtual Platform" -OR $model -eq "VirtualBox")
			{
				
				# Computer is a VM.
				$results.VM = "Yes"
			}
			Else
			{
			
				# Computer is not a VM.
				$results.VM = "No"
			}
			
			# Get the total physical memory.
			$results.Memory = [math]::Round($computerSystem.TotalPhysicalMemory/1GB)
			
			# Attempt to get information from the Win32_Processor class.
			Try
			{
				
				# Get the processor information.
				$processor = Get-WMIObject -Class Win32_Processor -ComputerName $ComputerName -ErrorAction Stop
			}
			Catch
			{
				
				# Capture the error.
				$wmiError = [string]$($error[0].Exception.Message)
			}	
			
			# If Win32_Processor results were obtained, then continue.
			If (!$wmiError)
			{
			
				# Get processor information.
				$results.MaxClockSpeed = [math]::Round(($processor[0].MaxClockSpeed/1000),2)
				$results.CPUBits = [string]$processor[0].AddressWidth
				$results.CPU = [string]$processor[0].Name
				$results.NumberOfCores = [string]$processor.NumberOfCores.Count
				$results.NumberOfLogicalProcessors = [string]$processor.NumberOfLogicalProcessors.Count
				
				# Attempt to get information from the Win32_BIOS class.
				Try
				{
					
					# Get the BIOS information.
					$bios = Get-WMIObject -Class Win32_BIOS -ComputerName $ComputerName -ErrorAction Stop
				}
				Catch
				{
					
					# Capture the error.
					$wmiError = [string]$($error[0].Exception.Message)
				}
				
				# If Win32_BIOS class results were obtained, then continue.
				If (!$wmiError)
				{
					
					# Get BIOS information.
					$results.SerialNumber = [string]$bios.SerialNumber
					$results.BIOSVersion = [string]$bios.BIOSVersion
					
					# Script was successful.
					$results.ScriptStatus = "OK"
				}
				Else
				{
					
					# Failed to get BIOS information.
					$results.ScriptStatus = "Failed - WMI Class: Win32_BIOS - $wmiError"
				}
			}
			Else
			{
				
				# Failed to get processor information.
				$results.ScriptStatus = "Failed - WMI Class: Win32_Processor - $wmiError"
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
		
		# Failed to connect to the computer.
		$results.ScriptStatus = "Failed - Could not connect to the computer"
	}

	# Create the header for the HTML output of the results. 
	$header = @" 
		<style>
		#tblToolOutput TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-family:verdana; 
		font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; text-align:center; 
		background-color:#39ac6b; color:white; font-weight:bold;} #tblToolOutput TD {border-width: 1px; padding: 3px; border-style: solid; 
		border-color: black;text-align:left;} #tblToolOutput td:nth-child(5){text-align:right;} #tblToolOutput td:nth-child(7){text-align:right;}
		#tblToolOutput td:nth-child(8){text-align:right;} #tblToolOutput td:nth-child(9){text-align:right;} 
		#tblToolOutput td:nth-child(10){text-align:right;}
		</style>
		<div id=tblToolOutput>
"@

	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$hardwareInfo = $results | Select-Object Computer, Manufacturer, Model, VM, @{Label="Memory(GB)"; Expression={$_.Memory} }, CPU, `
		@{ Label="MaxClockSpeed(Ghz)"; Expression={$_.MaxClockSpeed} }, CPUBits, NumberOfCores, NumberOfLogicalProcessors, SerialNumber, `
		BIOSVersion, ScriptStatus | ConvertTo-Html -Fragment -PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $hardwareInfo
}
