### System Frontier
[**http://systemfrontier.com**](http://systemfrontier.com/)

This custom tool is for use with System Frontier.  For more information, please visit: [http://systemfrontier.com/powershell](http://systemfrontier.com/powershell).

# Add-LocalGroupMember Custom Tool Setup Instructions

1. In System Frontier, click **Settings.**
2. Click **Custom Fields**.  For this tool you will need to set up 2 additional custom fields.

	![Custom Fields](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CustomFields.png "Custom Fields")

3. Click **New**.  The **New Custom Field** form will be displayed.

	![New Custom Field](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/NewCustomField.png "New Custom Field")

4. Enter the name:

	**LocalGroupName**

5. Enter the description:

	**Enter the name of the local group that exists on the computer**

6. Choose a data type of **text**.
7. Click **Save**.
8. Repeat steps 1-7 using this information:

	Name: **AccountName**

	Description:  **Enter either local account name or domain account name with this format (domain\accountname or 		accountname@domain)**

	Data type:   **text**

9. In System Frontier, click on **Tools > Create tool**.

	![Create Tool](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CreateTool.png "Create Tool")

10. Enter the tool name:

	**Add-LocalGroupMember**

11. Enter the description:

	**Adds a user or group to a local group on a computer.**

12. Select the appropriate category, then click **Choose File** to specify the applicable script to use for this tool.  Be sure to select this file:

	**Add-LocalGroupMember.ps1**

13. Click **Create**.
14. Once the tool is created, it will open up the **Custom Tool (Edit)** page.

	![CustomToolEdit](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CustomToolEdit.png "Custom Tool Edit")

15. Click **Modify**.
16. The **Custom Tool Input** page will be displayed.

	![Custom Tool Input](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/CustomToolInput.png "Custom Tool Input")

17. Select **LocalGroupName** and **AccountName**.
18. Click **Add**.
19. You will see **LocalGroupName** and **AccountName** appear under **Currently Mapped Input Fields**.

	![Local Group and Account Input Fields](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/LocalGroupAccountInputFields.png "Local Group and Account Input Fields")

20. Click **Done**.
21. You will be returned to the **Custom Tool (Edit)** page.  Scroll down to the Arguments section.

	![Local Group and Account Fields](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/LocalGroupAccountFields.png "Local Group and Account Fields")

	Within the Arguments field, type:

 	**-ComputerName &quot;{$TargetHostname}&quot; -LocalGroupName &quot;{$Custom[LocalGroupName]}&quot; -AccountName &quot;{$Custom[AccountName]}&quot;**

22. Scroll down to the **Permissions** section.

	![Permissions](https://github.com/systemfrontier/customtools-starterkit/blob/master/images/Permissions.png "Permissions")

23. Select the **Assigned Roles**.  The roles selected will have access to run this tool.
24. Click **Save**.

The setup and configuration for this custom tool is complete.
