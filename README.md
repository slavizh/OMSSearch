# OMSSearch
OMSSearch is a PowerShell module for Azure Automation that will help you execute queries against Microsoft Operations Management Suite.
The module uses ADAL to get Token from Azure AD.

# Prerequisites
1. Your OMS workspace is linked to your Azure Subscription
2. Find your Subscription ID
3. Find what is the name of the resource group where your OMS workspaces is located. ARM explorer (https://resources.azure.com/) can help you.
3. Know the name of your OMS workspace in Azure
# Instructions
1. Archive all files in a OMSSearch.zip file
2. Add module to Azure Automation
4. Create Connection in Azure Automation of type OMSConnection where TenantADName is the UPN with which your Azure AD accounts are created 
(example stasoutlook.onmicrosoft.com), Username is a UPN account in your Azure AD that has access to OMS and Password is the password for that account.
3. Enjoy

# Notes
Execute-OMSSearchQuery cmdlet uses System.Web.Script.Serialization.JavaScriptSerializer which cannot deserialize value bigger than int32. When you return 
data with Start, End and Top make sure you are returning information in JSON format that is lower than 2,147,483,647 characters.

Start and End paramteres take the date format in UTC like this "yyyy-MM-ddTHH:mm:ss:fffZ". You can use PowerShell to get such values like:
((get-date).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ss:fffZ")
(((get-date)).AddHours(-6).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ss:fffZ")

# Versions
## 5.1.4
*	Changed time format for paramaters "Start" and "End" from "yyyy-MM-ddTHH:mm:ss:fffZ" to "yyyy-MM-ddTHH:mm:ss.fffZ". The initial format was incorrect which resulted in false queries.

## 5.1.3
*	Get-OMSSavedSearches was renamed to Get-OMSSavedSearch . Alias for Get-OMSSavedSearches  is created.
*	New function Get-ARMAzureSubscription
*	New function Invoke-OMSSavedSearch 
*	Authors list in the module manifest is updated
*	Added APIVersion parameter to almost all cmdlets
*	Added Get-OMSResourceGroup to be visible
*	Updated all cmdlet examples with the new APIVersion parameter

## 5.1.0
*	Function Execute-OMSSearchQuery renamed to Invoke-OMSSearchQuery. Alias create for Execute-OMSSearchQuery.
*	Internal function Import-ADALDll is not shown anymore.
*	Switched to new API version 2015-03-20 that works in all regions
*	Function Get-AADToken no longer has separate parameters for UserName and Password. Now it is one paramter Credential. Makes the module compliant with PowerShell Gallery.

# Examples
```PowerShell
workflow Get-SavedSearches
{	
	$OMSCon = Get-AutomationConnection -Name 'stasoutlook'
	$Token = Get-AADToken -OMSConnection $OMSCon
	$subscriptionId = "3c1d68a5-4064-4522-94e4-e03781655555e"
	$ResourceGroupName = "oi-default-east-us"
	$OMSWorkspace = "test"	
	
	Get-OMSSavedSearches `
		-OMSWorkspaceName $OMSWorkspace  `
		-ResourceGroupName $ResourceGroupName `
		-SubscriptionID $subscriptionId `
		-Token $Token
}
```
```PowerShell
workflow Get-RestartedComputers
{	
	$OMSCon = Get-AutomationConnection -Name 'stasoutlook'
	$Token = Get-AADToken -OMSConnection $OMSCon
	$subscriptionId = "3c1d68a5-4064-4522-94e4-e03781655555e"
	$ResourceGroupName = "oi-default-east-us"
	$OMSWorkspace = "test"	
	$Query = "shutdown Type=Event EventLog=System Source=User32 EventID=1074 | Select TimeGenerated,Computer"
	
	Execute-OMSSearchQuery -SubscriptionID $subscriptionId `
	                       -ResourceGroupName $ResourceGroupName  	`
						   -OMSWorkspaceName $OMSWorkspace `
						   -Query $Query `
						   -Token $Token
}
```
```PowerShell
workflow Get-LastOMSData
{	
	$OMSCon = Get-AutomationConnection -Name 'stasoutlook'
	$Token = Get-AADToken -OMSConnection $OMSCon
	$subscriptionId = "3c1d68a5-4064-4522-94e4-e03781655555e"
	$ResourceGroupName = "oi-default-east-us"
	$OMSWorkspace = "test"	 
    $Query = '*'
	$StartTime = (((get-date)).AddHours(-6).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ss:fffZ")
    $EndTime = ((get-date).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ss:fffZ")
    Execute-OMSSearchQueryV2 -SubscriptionID $subscriptionId `
                           -ResourceGroupName $ResourceGroupName    `
                           -OMSWorkspaceName $OMSWorkspace `
                           -Query $Query `
                           -Token $Token `
						   -top 500 `
						   -Start $StartTime `
						   -End $EndTime

						   
}
```
```PowerShell
workflow Get-MYOMSWorkspace
{	
	$OMSCon = Get-AutomationConnection -Name 'stasoutlook'
    $Token = Get-AADToken -OMSConnection $OMSCon
    $subscriptionId = "3c1d68a5-4064-4522-94e4-e0378165922e"
		Get-OMSWorkspace `
		-SubscriptionID $subscriptionId `
		-Token $Token
						   
}
```
# Blogpost
https://cloudadministrator.wordpress.com/2015/06/05/programmatically-search-operations-management-suite/