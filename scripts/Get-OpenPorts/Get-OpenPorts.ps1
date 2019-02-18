<#
	.SYNOPSIS
		Gets open ports information from a computer.
	.DESCRIPTION
		This script retrieves OpenPort, PortName and PortStatus information from a computer.
	.PARAMETER ComputerName
		The name of the target computer.
	.EXAMPLE
		.\Get-OpenPorts.ps1 -ComputerName "COMP01"
	.NOTES
		Name:		Get-OpenPorts
		Author:		Noxigen,LLC
		Website:	https://systemfrontier.com

		The output is HTML formatted as a table.
		Copy and paste the output to an Excel spreadsheet, if desired.
		This script is used in the Custom Tools section of System Frontier.
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-operatingsystem
	.LINK		
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-processor
	.LINK
		https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-process
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

	# Function to do the port check.
	Function Get-PortStatus
	{
		
		# Get the parameters.
		Param(
			[Parameter(ValueFromPipeline=$False, Position=0, Mandatory=$true)]
			[String]$ComputerName,
			[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$true)]
			[int]$Port,
			[Parameter(ValueFromPipeline=$False, Position=2, Mandatory=$true)]
			[int]$Timeout
		)
		
		# Initially set the result to false.
		$result = $false
		
		# Create the TCP object.
		$tcpClient = New-Object System.Net.Sockets.TCPClient
		
		# Set the TCP receive timeout.
		$tcpClient.ReceiveTimeout = $Timeout
		
		# Set the TCP send timeout.
		$tcpClient.SendTimeout = $Timeout
		
		# Attempt a TCP connection to the port.
		Try
		{
			
			# Connect to the port.
			$tcpClient.Connect($ComputerName, $Port)
		}
		Catch
		{
			
			# Do nothing.  Already set the result to false at the beginning of this function.
		}
		
		# If the connection to the port was successful, then continue.
		If ($tcpClient.Connected) 
		{
			
			# Port connection was successful.
			$result = $true
		}
		
		# Close the TCP instance and connection.
		$tcpClient.Close()
		
		# Return the result.
		$result
	}

	# Remove any leading/trailing spaces from $ComputerName.
	$ComputerName = $ComputerName.trim()
	
	# Set the port check attempt time limit in milliseconds.
	$Timeout = 100
	
	# Set an initial results status.
	$resultsStatus = "Failed - Script failed to complete."
	
	# Create an array to hold the final data.
	$results = @()

	# Create a hashtable containing the port numbers (keys) and port names (values). Keys must be strings.
	$ports = [ordered]@{}
	$ports["7"] = "echo"
	$ports["9"] = "discard"
	$ports["11"] = "Active users"
	$ports["13"] = "daytime"
	$ports["17"] = "Quote of the day"
	$ports["19"] = "Character generator"
	$ports["20"] = "FTP,  data"
	$ports["21"] = "FTP. control"
	$ports["22"] = "SSH Remote Login Protocol"
	$ports["23"] = "telnet"
	$ports["25"] = "Simple Mail Transfer Protocol"
	$ports["37"] = "time"
	$ports["39"] = "Resource Location Protocol"
	$ports["42"] = "Host Name Server"
	$ports["43"] = "nicname"
	$ports["53"] = "Domain Name Server"
	$ports["67"] = "Bootstrap Protocol Server"
	$ports["68"] = "Bootstrap Protocol Client"
	$ports["69"] = "Trivial File Transfer"
	$ports["70"] = "gopher"
	$ports["79"] = "finger"
	$ports["80"] = "World Wide Web"
	$ports["81"] = "HOSTS2 Name Server"
	$ports["88"] = "Kerberos"
	$ports["101"] = "NIC Host Name Server"
	$ports["102"] = "ISO-TSAP Class 0"
	$ports["107"] = "Remote Telnet Service"
	$ports["109"] = "Post Office Protocol - Version 2"
	$ports["110"] = "Post Office Protocol - Version 3"
	$ports["111"] = "SUN Remote Procedure Call"
	$ports["113"] = "Identification Protocol"
	$ports["117"] = "uucp-path"
	$ports["118"] = "SQL Services"
	$ports["119"] = "Network News Transfer Protocol"
	$ports["123"] = "Network Time Protocol"
	$ports["135"] = "DCE endpoint resolution"
	$ports["137"] = "NETBIOS Name Service"
	$ports["138"] = "NETBIOS Datagram Service"
	$ports["139"] = "NETBIOS Session Service"
	$ports["143"] = "Internet Message Access Protocol"
	$ports["150"] = "sql-net"
	$ports["156"] = "sqlsrv"
	$ports["158"] = "PCMail Server"
	$ports["161"] = "SNMP"
	$ports["162"] = "SNMP trap"
	$ports["170"] = "Network PostScript"
	$ports["179"] = "Border Gateway Protocol"
	$ports["194"] = "Internet Relay Chat Protocol"
	$ports["213"] = "IPX over IP"
	$ports["322"] = "rtsps"
	$ports["349"] = "mftp"
	$ports["389"] = "Lightweight Directory Access Protocol"
	$ports["443"] = "HTTP over TLS"
	$ports["445"] = "microsoft-ds"
	$ports["464"] = " Kerberos-v5"
	$ports["500"] = "Internet Key Exchange"
	$ports["507"] = "Content Replication System"
	$ports["512"] = "Remote Process Execution"
	$ports["513"] = "Remote Login"
	$ports["514"] = "cmd"
	$ports["515"] = "printer"
	$ports["517"] = "talk"
	$ports["518"] = "ntalk"
	$ports["520"] = "Extended File Name Server"
	$ports["522"] = "ulp"
	$ports["525"] = "timed"
	$ports["526"] = "tempo"
	$ports["529"] = "irc-serv"
	$ports["530"] = "courier"
	$ports["531"] = "conference"
	$ports["532"] = "netnews"
	$ports["533"] = "For emergency broadcasts"
	$ports["540"] = "uucp"
	$ports["543"] = "Kerberos login"
	$ports["544"] = "Kerberos remote shell"
	$ports["546"] = "DHCPv6 Client"
	$ports["547"] = "DHCPv6 Server"
	$ports["548"] = "AFP over TCP"
	$ports["550"] = "new-rwho"
	$ports["554"] = "Real Time Stream Control Protocol"
	$ports["556"] = "remotefs"
	$ports["560"] = "rmonitor"
	$ports["561"] = "monitor"
	$ports["563"] = "NNTP over TLS"
	$ports["565"] = "whoami"
	$ports["568"] = "Microsoft shuttle"
	$ports["569"] = "Microsoft rome"
	$ports["593"] = "HTTP RPC Ep Map"
	$ports["612"] = "HMMP Indication"
	$ports["613"] = "HMMP Operation"
	$ports["636"] = "LDAP over TLS"
	$ports["666"] = "Doom Id Software"
	$ports["691"] = "MS Exchange Routing"
	$ports["749"] = "Kerberos administration"
	$ports["750"] = "Kerberos version IV"
	$ports["800"] = "mdbs_daemon"
	$ports["989"] = "FTP data,  over TLS"
	$ports["990"] = "FTP control,  over TLS"
	$ports["992"] = "Telnet protocol over TLS"
	$ports["993"] = "IMAP4 protocol over TLS"
	$ports["994"] = "IRC protocol over TLS"
	$ports["995"] = "pop3 protocol over TLS"
	$ports["1109"] = "Kerberos POP"
	$ports["1110"] = "Cluster status info"
	$ports["1155"] = "Network File Access"
	$ports["1034"] = "ActiveSync Notifications"
	$ports["1167"] = "Conference calling"
	$ports["1270"] = "Microsoft Operations Manager"
	$ports["1433"] = "Microsoft-SQL-Server"
	$ports["1434"] = "Microsoft-SQL-Monitor"
	$ports["1477"] = "ms-sna-server"
	$ports["1478"] = "ms-sna-base"
	$ports["1512"] = "Microsoft Windows Internet Name Service"
	$ports["1524"] = "ingreslock"
	$ports["1607"] = "stt"
	$ports["1701"] = "Layer Two Tunneling Protocol"
	$ports["1711"] = "pptconference"
	$ports["1723"] = "Point-to-point tunnelling protocol"
	$ports["1731"] = "msiccp"
	$ports["1745"] = "remote-winsock"
	$ports["1755"] = "ms-streaming"
	$ports["1801"] = "Microsoft Message Queue"
	$ports["1812"] = "RADIUS authentication protocol"
	$ports["1813"] = "RADIUS accounting protocol"
	$ports["1863"] = "msnp"
	$ports["1900"] = "ssdp"
	$ports["1944"] = "close-combat"
	$ports["2049"] = "NFS server"
	$ports["2053"] = "Kerberos de-multiplexor"
	$ports["2106"] = "Multicast-Scope Zone Announcement Protocol"
	$ports["2177"] = "QWAVE"
	$ports["2234"] = "DirectPlay"
	$ports["2382"] = "Microsoft OLAP 3"
	$ports["2383"] = "Microsoft OLAP 4"
	$ports["2393"] = "Microsoft OLAP 1"
	$ports["2394"] = "Microsoft OLAP 2"
	$ports["2460"] = "ms-theater"
	$ports["2504"] = "Microsoft Windows Load Balancing Server"
	$ports["2525"] = "Microsoft V-Worlds "
	$ports["2701"] = "SMS RCINFO"
	$ports["2702"] = "SMS XFER"
	$ports["2703"] = "SMS CHAT"
	$ports["2704"] = "SMS REMCTRL"
	$ports["2725"] = "MSOLAP PTP2"
	$ports["2869"] = "icslap"
	$ports["3020"] = "cifs"
	$ports["3074"] = "Microsoft Xbox game port"
	$ports["3126"] = "Microsoft .NET ster port"
	$ports["3132"] = "Microsoft Business Rule Engine Update Service"
	$ports["3268"] = "Microsoft Global Catalog"
	$ports["3269"] = "Microsoft Global Catalog with LDAP"
	$ports["3343"] = "Microsoft Cluster Net"
	$ports["3389"] = "MS WBT Server"
	$ports["3535"] = "Microsoft Class Server"
	$ports["3540"] = "PNRP User Port"
	$ports["3544"] = "Teredo Port"
	$ports["3587"] = "Peer to Peer Grouping"
	$ports["3702"] = "WS-Discovery"
	$ports["3776"] = "Device Provisioning Port"
	$ports["3847"] = "Microsoft Firewall Control"
	$ports["3882"] = "DTS Service Port"
	$ports["3935"] = "SDP Port Mapper Protocol"
	$ports["4350"] = "Net Device"
	$ports["4500"] = "Microsoft IPsec NAT-T"
	$ports["5355"] = "LLMNR "
	$ports["5357"] = "Web Services on devices "
	$ports["5358"] = "Web Services on devices"
	$ports["5678"] = "Remote Replication Agent Connection"
	$ports["5679"] = "Direct Cable Connect Manager"
	$ports["5720"] = "Microsoft Licensing"
	$ports["6073"] = "DirectPlay8"
	$ports["9535"] = "Remote Man Server"
	$ports["9753"] = "rasadv"
	$ports["11320"] = "IMIP Channels Port"
	$ports["47624"] = "Direct Play Server"

	# Create an array to hold the port numbers (using this is faster than pulling the numbers from the hashtable keys).
	$portNumbers += 7, 9, 11, 13, 17, 19, 20, 21, 22, 23, 25, 37, 39, 42, 43, 53, 67, 68, 69, 70, 79, 80, 81, 88, 101 
	$portNumbers += 102, 107, 109, 110, 111, 113, 117, 118, 119, 123, 135, 137, 138, 139, 143, 150, 156, 158, 161, 162
	$portNumbers += 170, 179, 194, 213, 322, 349, 389, 443, 445, 464, 500, 507, 512, 513, 514, 515, 517, 518, 520, 522
	$portNumbers += 525, 526, 529, 530, 531, 532, 533, 540, 543, 544, 546, 547, 548, 550, 554, 556, 560, 561, 563, 565
	$portNumbers += 568, 569, 593, 612, 613, 636, 666, 691, 749, 750, 800, 989, 990, 992, 993, 994, 995, 1109, 1110
	$portNumbers += 1155, 1034, 1167, 1270, 1433, 1434, 1477, 1478, 1512, 1524, 1607, 1701, 1711, 1723, 1731, 1745
	$portNumbers += 1755, 1801, 1812, 1813, 1863, 1900, 1944, 2049, 2053, 2106, 2177, 2234, 2382, 2383, 2393, 2394
	$portNumbers += 2460, 2504, 2525, 2701, 2702, 2703, 2704, 2725, 2869, 3020, 3074, 3126, 3132, 3268, 3269, 3343
	$portNumbers += 3389, 3535, 3540, 3544, 3587, 3702, 3776, 3847, 3882, 3935, 4350, 4500, 5355, 5357, 5358, 5678
	$portNumbers += 5679, 5720, 6073, 9535, 9753, 11320, 47624
	
	# If we can connect to the computer, then continue.
	If (Test-Connection $ComputerName -count 1 -quiet)
	{

		# Iterate through each port number.
		ForEach ($PortNumber in $portNumbers) 
		{
		
			# Check the port to see if it is open.
			If ((Get-PortStatus -ComputerName $ComputerName -Port $PortNumber -Timeout $Timeout) -eq $true )
			{
				
				# Get the port name
				$portName = $ports[[String]$PortNumber]
				
				# Add the port information to the object.
				$portInfo = New-Object psobject -Property @{
					Computer = $ComputerName
					OpenPort = $PortNumber
					PortName = $portName
					PortStatus = "Open"
					ScriptStatus = "OK"
				}
				
				# Add the object to the final results.
				$results += $portInfo
			}
		}
	} 
	Else
	{
		
		# Failed to connect to the computer.
		$resultsStatus = "Failed - Could not connect to the computer."
	}

	# If there was a failure, then continue.
	If ($resultsStatus -contains "Failed*")
	{
		
		# Create a custom object to hold the failure information.
		$portInfo = [pscustomobject]@{
			Computer = $ComputerName
			OpenPort = ""
			PortName = ""
			PortStatus = $resultsStatus
			ScriptStatus = "OK"
		}
		
		# Update the results.
		$results += $portInfo
	}
	
	# Create the header for the HTML output of the results. The "@ at the end must be leftmost on the line or powershell won't recognize it properly.
	$header = @"
	<style>
	#tblToolOutput TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; font-family:verdana; 
	font-size:small;} #tblToolOutput TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; text-align:left; 
	background-color:#39ac6b; color:white; font-weight:bold;} #tblToolOutput TD {border-width: 1px; padding: 3px; border-style: solid; 
	border-color: black;} #tblToolOutput td:nth-child(2){text-align:right;}
	</style>
	<div id=tblToolOutput>
"@
	
	# Create the footer for the HTML output of the results.
	$footer = "</div>"
	
	# Format the results.
	$openPorts = $results | Sort OpenPort | Select-Object Computer,  OpenPort,  PortName,  PortStatus, ScriptStatus | ConvertTo-Html -Fragment `
		-PreContent $header -PostContent $footer
	
	# Display the results.
	Write-Output $openPorts	
}
