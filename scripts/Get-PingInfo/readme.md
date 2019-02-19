### System Frontier
[**https://systemfrontier.com**](https://systemfrontier.com/)

This custom tool is for use with System Frontier.  For more information, please visit: [https://systemfrontier.com/powershell](https://systemfrontier.com/powershell).

# Get-PingInfo Custom Tool Setup Instructions

1. In System Frontier, click on **Tools > Create tool**.

	![Create Tool](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CreateTool.png "Create Tool")

2. Enter the tool name:

	**Get-PingInfo**

3. Enter the description:

	**Tests ping status and gets IP address information from a computer.**

4. Select the appropriate category, then click **Choose File** to specify the applicable script to use for this tool.  Be sure to select this file:

	**Get-PingInfo.ps1**

5. Click **Create**.

6. Once the tool is created, it will open up the **Custom Tool (Edit)** page.

	![CustomToolEdit](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CustomToolEdit.png "Custom Tool Edit")

7. Scroll down to the Arguments section.  For this tool, the only argument required will be the name of the computer.  Within the Arguments field, type: 

 	**-ComputerName &quot;{$TargetHostname}&quot;**

14. Scroll down to the **Permissions** section.

	![Permissions](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/Permissions.png "Permissions")

15. Select the **Assigned Roles**.  The roles selected will have access to run this tool.
16. Click **Save**.

The setup and configuration for this custom tool is complete.
