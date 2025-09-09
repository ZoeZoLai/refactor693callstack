<#
.SYNOPSIS
    Helper functions and utilities module
.DESCRIPTION
    Contains utility functions used across the ESS Health Checker application
    Following call stack principles with dependency injection
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

function Get-FormattedSiteIdentifier {
    <#
    .SYNOPSIS
        Formats site name with application alias for consistent display
    .DESCRIPTION
        Creates a consistent site identifier format for use in reports and health check messages
    .PARAMETER SiteName
        The IIS site name
    .PARAMETER ApplicationPath
        The application path/alias
    .RETURNS
        Formatted site identifier string
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SiteName,
        
        [Parameter(Mandatory = $false)]
        [string]$ApplicationPath = $null
    )
    
    if ($ApplicationPath -and $ApplicationPath -ne "/") {
        return "$SiteName - $($ApplicationPath.TrimStart('/'))"
    } else {
        return $SiteName
    }
}

function Get-AppPoolIdentity {
    <#
    .SYNOPSIS
        Get application pool identity information
    .DESCRIPTION
        Retrieves the identity type and username for a specific application pool
    .PARAMETER AppPoolName
        Name of the application pool to get identity information for
    .PARAMETER SystemInfo
        Optional system information object containing IIS data
    .RETURNS
        String containing the identity information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppPoolName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SystemInfo = $null
    )
    
    Write-Verbose "Get-AppPoolIdentity called with AppPoolName: '$AppPoolName'"
    
    if ($SystemInfo -and $SystemInfo.IIS -and $SystemInfo.IIS.ApplicationPools) {
        Write-Verbose "SystemInfo.IIS.ApplicationPools count: $($SystemInfo.IIS.ApplicationPools.Count)"
        $appPoolNames = $SystemInfo.IIS.ApplicationPools | ForEach-Object { $_.Name }
        Write-Verbose "Available app pools: $($appPoolNames -join ', ')"
        
        $appPool = $SystemInfo.IIS.ApplicationPools | Where-Object { $_.Name -eq $AppPoolName }
        if ($appPool) {
            Write-Verbose "Found app pool: $($appPool.Name)"
            $identityType = $appPool.ProcessModel.IdentityType
            $userName = $appPool.ProcessModel.UserName
            
            if ($identityType -eq "SpecificUser" -and $userName) {
                return "$identityType ($userName)"
            } else {
                return $identityType
            }
        } else {
            Write-Verbose "App pool '$AppPoolName' not found in SystemInfo"
        }
    } else {
        Write-Verbose "SystemInfo or IIS.ApplicationPools not available"
    }
    return "Unknown"
}

