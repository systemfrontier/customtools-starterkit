### System Frontier
[**https://systemfrontier.com**](https://systemfrontier.com/)

This custom tool is for use with System Frontier.  For more information, please visit: [https://systemfrontier.com/powershell](https://systemfrontier.com/powershell)..

# Start-Service Custom Tool Setup Instructions

1. In System Frontier, click **Settings.**
2. Click **Custom Fields**.  For this tool you will need to set up 1 additional custom field.

	![Custom Fields](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CustomFields.png "Custom Fields")

3. Click **New**.  The **New Custom Field** form will be displayed.

	![New Custom Field](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/NewCustomField.png "New Custom Field")

4. Enter the name:

	**ServiceName**

5. Enter the description:

	**Enter the name of the service (example: spooler)**

6. Choose a data type of **text**.
7. Click **Save**.
8. In System Frontier, click on **Tools > Create tool**.

	![Create Tool](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CreateTool.png "Create Tool")

9. Enter the tool name:

	**Start-Service**

10. Enter the description:

	**Starts a service on a computer.**

11. Select the appropriate category, then click **Choose File** to specify the applicable script to use for this tool.  Be sure to select this file:

	**Start-Service.ps1**

12. Click **Create**.
13. Once the tool is created, it will open up the **Custom Tool (Edit)** page.

	![CustomToolEdit](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CustomToolEdit.png "Custom Tool Edit")

14. Click **Modify**.
15. The **Custom Tool Input** page will be displayed.

	![Custom Tool Input](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CustomToolInput.png "Custom Tool Input")

18. Select **ServiceName**.
19. Click **Add**.
20. You will see **ServiceName** appear under **Currently Mapped Input Fields**.

	![Service Name Input Field](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/ServiceNameInputField.png "Service Name Input Field")

21. Click **Done**.
22. You will be returned to the **Custom Tool (Edit)** page.  Scroll down to the Arguments section.

	![Service Name Field](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/ServiceNameField.png "Service Name Field")

	Within the Arguments field, type:

 	**-ComputerName &quot;{$TargetHostname}&quot; -ServiceName &quot;{$Custom[ServiceName]}&quot;**

23. Scroll down to the **Permissions** section.

	![Permissions](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/Permissions.png "Permissions")

24. Select the **Assigned Roles**.  The roles selected will have access to run this tool.
25. Click **Save**.

The setup and configuration for this custom tool is complete.
