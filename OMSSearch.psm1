Function Import-ADALDll {
<# 
 .Synopsis
  Load Load Active Directory Authentication Library (ADAL) Assemblies

 .Description
   Load Load Active Directory Authentication Library (ADAL) Assemblies from either the Global Assembly Cache or from the DLLs located in OMSSearch PS module directory. It will use GAC if the DLLs are already loaded in GAC.

 .Example
  # Load the ADAL Dlls
   Import-ADALDll

#>
    
    $DLLPath = (Get-Module OMSSearch).ModuleBase
    $arrDLLs = @()
    $arrDLLs += 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
	$AssemblyVersion = "2.14.0.0"
	$AssemblyPublicKey = "31bf3856ad364e35"
    $bSDKLoaded = $true

    Foreach ($DLL in $arrDLLs)
    {
        $AssemblyName = $DLL.TrimEnd('.dll')
        If (!([AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq "$AssemblyName, Version=$AssemblyVersion, Culture=neutral, PublicKeyToken=$AssemblyPublicKey"}))
		{
			Write-verbose 'Loading Assembly $AssemblyName...'
			Try {
                $DLLFilePath = Join-Path $DLLPath $DLL
                [Void][System.Reflection.Assembly]::LoadFrom($DLLFilePath)
            } Catch {
                Write-Verbose "Unable to load $DLLFilePath. Please verify if the DLLs exist in this location!"
                $bSDKLoaded = $false
            }
		}
    }
    $bSDKLoaded
}
Function Get-AADToken {
        
        [CmdletBinding()]
        PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$OMSConnection,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the user name to connect to the SharePoint Online site')][Alias('t')][String]$TenantADName,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the user name to connect to the SharePoint Online site')][Alias('u')][String]$Username,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the password to connect to the SharePoint Online site')][Alias('p')][String]$Password
        )

    $ImportSDK = Import-ADALDll
	If ($ImportSDK -eq $false)
	{
		Write-Error "Unable to load ADAL DLL. Aborting."
		Return
	}
    If ($OMSConnection)
	{
		$Username       = $OMSConnection.Username
		$Password       = $OMSConnection.Password
        $TenantADName   = $OMSConnection.TenantADName

	} else {
		
	}
    # Set well-known client ID for Azure PowerShell
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    
    # Set redirect URI for Azure PowerShell
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    # Set Resource URI to Azure Service Management API
    $resourceAppIdURI = "https://management.core.windows.net/"

    # Set Authority to Azure AD Tenant
    $authority = "https://login.windows.net/$TenantADName"

	$credential = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential" -ArgumentList $Username,$Password
    # Create AuthenticationContext tied to Azure AD Tenant
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    $authResult = $authContext.AcquireToken($resourceAppIdURI,$clientId,$credential)
    $Token = $authResult.CreateAuthorizationHeader()

	Return $Token
}
Function Get-OMSSavedSearches {

<# 
 .Synopsis
  Gets Saved Searches from OMS workspace

 .Description
   Gets Saved Searches from OMS workspace

 .Example
  # Gets Saved Searches from OMS. Returns results.
  $OMSCon = Get-AutomationConnection -Name 'OMSCon'
  $Token = Get-AADToken -OMSConnection $OMSCon
  $subscriptionId = "3c1d68a5-4064-4522-94e4-e0378165555e"
  $ResourceGroupName = "oi-default-east-us"
  $OMSWorkspace = "Test"	
  Get-OMSSavedSearches -SubscriptionID $subscriptionId -ResourceGroupName $ResourceGroupName  -OMSWorkspaceName $OMSWorkspace -Token $Token

#>

    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][string]$SubscriptionID,
        [Parameter(Mandatory=$true)][String]$ResourceGroupName,
        [Parameter(Mandatory=$true)][String]$OMSWorkspaceName,
        [Parameter(Mandatory=$true)][String]$Token

    )
    $uri = "https://management.azure.com/subscriptions/" + $SubscriptionID + "/resourcegroups/" + $ResourceGroupName + "/providers/microsoft.operationalinsights/workspaces/" + $OMSWorkspaceName + "/savedSearches?api-version=2014-10-10"
    $headers = @{"Authorization"=$Token;"Accept"="application/json"}
    $headers.Add("Content-Type","application/json")
    $result = Invoke-WebRequest -Method Get -Uri $uri -Headers $headers -UseBasicParsing
    if($result.StatusCode -ge 200 -and $result.StatusCode -le 399){
      if($result.Content -ne $null){
        $json = (ConvertFrom-Json $result.Content)
        if($json -ne $null){
          $return = $json
          if($json.value -ne $null){$return = $json.value}
        }
      }
    }

    else{
    Write-Error "Failed to egt saved searches. Check parameters."
  }
  return $return
}


Function Execute-OMSSearchQuery {

<# 
 .Synopsis
  Executes Search Query against OMS

 .Description
   Executes Search Query against OMS

 .Example
  # Executes Search Query against OMS. Returns results from query.
  $OMSCon = Get-AutomationConnection -Name 'OMSCon'
  $Token = Get-AADToken -OMSConnection $OMSCon
  $subscriptionId = "3c1d68a5-4064-4522-94e4-e0378165555e"
  $ResourceGroupName = "oi-default-east-us"
  $OMSWorkspace = "Test"	
  $Query = "shutdown Type=Event EventLog=System Source=User32 EventID=1074 | Select TimeGenerated,Computer"
  Execute-OMSSearchQuery -SubscriptionID $subscriptionId -ResourceGroupName $ResourceGroupName  -OMSWorkspaceName $OMSWorkspace -Query $Query -Token $Token

#>

    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][string]$SubscriptionID,
        [Parameter(Mandatory=$true)][String]$ResourceGroupName,
        [Parameter(Mandatory=$true)][String]$OMSWorkspaceName,
        [Parameter(Mandatory=$true)][String]$Query,
        [Parameter(Mandatory=$true)][String]$Token

    )
    $uri = "https://management.azure.com/subscriptions/" + $SubscriptionID + "/resourcegroups/" + $ResourceGroupName + "/providers/microsoft.operationalinsights/workspaces/" + $OMSWorkspaceName + "/search?api-version=2014-10-10"
    $QueryArray = @{Query=$Query}
    $enc = New-Object "System.Text.ASCIIEncoding"
    $body = ConvertTo-Json -InputObject $QueryArray
    $byteArray = $enc.GetBytes($body)
    $contentLength = $byteArray.Length
    $headers = @{"Authorization"=$Token;"Accept"="application/json"}
    $headers.Add("Content-Length",$contentLength)
    $headers.Add("Content-Type","application/json")
    $result = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -Body $body -UseBasicParsing
    if($result.StatusCode -ge 200 -and $result.StatusCode -le 399){
      if($result.Content -ne $null){
        $json = (ConvertFrom-Json $result.Content)
        if($json -ne $null){
          $return = $json
          if($json.value -ne $null){$return = $json.value}
        }
      }
    }

    else{
    Write-Error "Failed to execute query. Check parameters."
  }
  return $return
}


Function Get-OMSWorkspace {
<# 
 .Synopsis
  Get OMS Workspaces

 .Description
  Get OMS Workspaces

 .Example
  $subscriptionId = "3c1d68a5-4064-4522-94e4-e0378165555e"
  Get-OMSWorkspace -SubscriptionId $Subscriptionid

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][string]$SubscriptionID,
        [Parameter(Mandatory=$true)][String]$Token

    )
    $uri = "https://management.azure.com/subscriptions/" + $SubscriptionID + "/providers/microsoft.operationalinsights/workspaces?api-version=2014-10-10"
    $headers = @{"Authorization"=$Token;"Accept"="application/json"}
    $headers.Add("Content-Type","application/json")
    $result = Invoke-WebRequest -Method Get -Uri $uri -Headers $headers -UseBasicParsing
    if($result.StatusCode -ge 200 -and $result.StatusCode -le 399){
      if($result.Content -ne $null){
        $json = (ConvertFrom-Json $result.Content)
        if($json -ne $null){
          $return = $json
          if($json.value -ne $null){$return = $json.value}
        }
      }
    }

    else{
    Write-Error "Failed to get OMS Workspaces. Check parameters."
  }
  return $return
}