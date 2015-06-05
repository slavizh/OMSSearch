# OMSSearch
OMSSearch is a PowerShell module for Azure Automation that will help you execute queries against Microsoft Operations Management Suite.
The module uses ADAL to get Token from Azure AD.

# Instructions
1. Archive all files in a OMSSearch.zip file
2. Add module to Azure Automation
4. Create Connection in Azure Automation of type OMSConnection where TenantADName is the UPN with which your Azure AD accounts are created 
(example stasoutlook.onmicrosoft.com), Username is a UPN account in your Azure AD that has access to OMS and Password is the password for that account.
3. Enjoy

# Examples
``workflow Get-SavedSearches
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
}``


``workflow Get-RestartedComputers
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
}``