﻿Function Get-AADToken {
        
        [CmdletBinding()]
        PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true)][Alias('Connection','c')][Object]$OMSConnection,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$true)][Alias('t')][String]$TenantADName,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$true)][Alias('cred')][pscredential]$Credential
        )

    If ($OMSConnection)
	{
		$Username       = $OMSConnection.Username
		$Password       = $OMSConnection.Password
        $TenantADName   = $OMSConnection.TenantADName

	} else {
        $Username       = $Credential.Username
		$Password       = $Credential.Password
	}
    # Set well-known client ID for Azure PowerShell
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    
    # Set redirect URI for Azure PowerShell
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    # Set Resource URI to Azure Service Management API
    $resourceAppIdURI = "https://management.core.windows.net/"

    # Set Authority to Azure AD Tenant
    $authority = "https://login.windows.net/$TenantADName"

	$AADcredential = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential" -ArgumentList $Username,$Password
    # Create AuthenticationContext tied to Azure AD Tenant
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    $authResult = $authContext.AcquireToken($resourceAppIdURI,$clientId,$AADcredential)
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
    $APIVersion = "2015-03-20"
    $uri = "https://management.azure.com/subscriptions/{0}/resourcegroups/{1}/providers/microsoft.operationalinsights/workspaces/{2}/savedSearches?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $OMSWorkspaceName, $APIVersion
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
Function Invoke-OMSSearchQuery {

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
  $NumberOfResults = 150
  $StartTime = (((get-date)).AddHours(-6).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ss:fffZ")
  $EndTime = ((get-date).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ss:fffZ")
  Execute-OMSSearchQuery -SubscriptionID $subscriptionId -ResourceGroupName $ResourceGroupName  -OMSWorkspaceName $OMSWorkspace -Query $Query -Token $Token
  Execute-OMSSearchQuery -SubscriptionID $subscriptionId -ResourceGroupName $ResourceGroupName  -OMSWorkspaceName $OMSWorkspace -Query $Query -Token $Token -Top $NumberOfResults -Start $StartTime -End $EndTime

#>

    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][Parameter(Mandatory=$true,ParameterSetName="DateTime")][string]$SubscriptionID,
        [Parameter(Mandatory=$true)][Parameter(Mandatory=$true,ParameterSetName="DateTime")][String]$ResourceGroupName,
        [Parameter(Mandatory=$true)][Parameter(Mandatory=$true,ParameterSetName="DateTime")][String]$OMSWorkspaceName,
        [Parameter(Mandatory=$true)][Parameter(Mandatory=$true,ParameterSetName="DateTime")][String]$Query,
        [Parameter(Mandatory=$true)][Parameter(Mandatory=$true,ParameterSetName="DateTime")][String]$Token,
        [Parameter(Mandatory=$false)][Parameter(Mandatory=$false,ParameterSetName="DateTime")][int]$Top,
        [Parameter(Mandatory=$false)][ValidatePattern("\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}:\d{3}Z")][string]$Start,
        [Parameter(Mandatory=$false)][ValidatePattern("\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}:\d{3}Z")][string]$End

    )
    $APIVersion = "2015-03-20"
    $uri = "https://management.azure.com/subscriptions/{0}/resourcegroups/{1}/providers/microsoft.operationalinsights/workspaces/{2}/search?api-version={3}" -f $SubscriptionID, $ResourceGroupName, $OMSWorkspaceName, $APIVersion
    $QueryArray = @{Query=$Query}
    if ($Start -and $End) { 
        $QueryArray+= @{Start=$Start}
        $QueryArray+= @{End=$End}
        }
    if ($Top) {
        $QueryArray+= @{Top=$Top}
        }
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
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")        
        $jsonserial= New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer 
        $jsonserial.MaxJsonLength  =  [int]::MaxValue
        $json = $jsonserial.DeserializeObject($result.Content)
        if($json -ne $null){
          $return = $json
          if($json.value -ne $null){$return = $json.value}
          Write-Verbose "Number of records returned from search: $($return.count)."
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
  $SubscriptionId = "3c1d68a5-4064-4522-94e4-e0378165555e"
  $Token = Get-AADToken -OMSConnection $OMSCon
  Get-OMSWorkspace -SubscriptionId $Subscriptionid -Token $Token

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][string]$SubscriptionID,
        [Parameter(Mandatory=$true)][String]$Token

    )
    $uri = "https://management.azure.com/subscriptions/{0}/providers/microsoft.operationalinsights/workspaces?api-version=2014-10-10" -f $SubscriptionID
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
    Write-Error 'Failed to get OMS Workspaces. Check parameters.'
  }
  return $return
}

Function Get-OMSResourceGroup {
<# 
 .Synopsis
  Get Azure Resource Group used by Operational Insights

 .Description
  Get Azure Resource Group used by Operational Insights

 .Example
  $SubscriptionId = "3c1d68a5-4064-4522-94e4-e0378165555e"
  $Token = Get-AADToken -OMSConnection $OMSCon
  Get-OMSResourceGroup -SubscriptionId $Subscriptionid -Token $Token

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][string]$SubscriptionID,
        [Parameter(Mandatory=$true)][String]$Token

    )
    $uri = "https://management.azure.com/subscriptions/{0}/resourceGroups?api-version=2014-04-01" -f $SubscriptionID
    Write-Verbose "URL: $uri"
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
    Write-Error 'Failed to get OMS Resource Group. Check parameters.'
  }
  #Filter out all none OMS resource groups
  $arrOMSResourceGroups = @()
  Foreach ($resourceGroup in $return)
  {
    if ($resourceGroup.name -imatch "^OI-Default-")
    {
        $arrOMSResourceGroups += $resourceGroup
    }
  }
  Write-Verbose "Total OMS resource groups found: $($arrOMSResourceGroups.count)."
  ,$arrOMSResourceGroups
}

#Load Load Active Directory Authentication Library (ADAL) Assemblies
If (!([AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq "Microsoft.IdentityModel.Clients.ActiveDirectory, Version=2.14.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"}))
{
	Write-verbose 'Microsoft.IdentityModel.Clients.ActiveDirectory...'
	Try {
        $ADALDllFilePath = Join-Path $PSScriptRoot "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        Add-Type -path $ADALDllFilePath
    } Catch {
        Throw "Unable to load $ADALDllFilePath. Please verify if the DLLs exist in this location!"
    }
}
New-Alias -Name Execute-OMSSearchQuery -Value Invoke-OMSSearchQuery -Scope Global
Export-ModuleMember -Alias Execute-OMSSearchQuery
Export-ModuleMember -Function *