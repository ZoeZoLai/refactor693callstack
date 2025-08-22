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
    
    if ($SystemInfo -and $SystemInfo.IIS -and $SystemInfo.IIS.ApplicationPools) {
        $appPool = $SystemInfo.IIS.ApplicationPools | Where-Object { $_.Name -eq $AppPoolName }
        if ($appPool) {
            $identityType = $appPool.ProcessModel.IdentityType
            $userName = $appPool.ProcessModel.UserName
            
            if ($identityType -eq "SpecificUser" -and $userName) {
                return "$identityType ($userName)"
            } else {
                return $identityType
            }
        }
    }
    return "Unknown"
}

function Get-InstanceAlias {
    <#
    .SYNOPSIS
        Gets the IIS application alias from the application path
    .DESCRIPTION
        Extracts the IIS application alias from the application path
    .PARAMETER SiteName
        IIS site name
    .PARAMETER ApplicationPath
        Application path
    .PARAMETER Type
        Instance type (ESS or WFE) - not used, kept for compatibility
    .RETURNS
        IIS application alias
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SiteName,
        
        [Parameter(Mandatory = $true)]
        [string]$ApplicationPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("ESS", "WFE")]
        [string]$Type
    )

    try {
        # Extract the last part of the application path (the actual IIS application alias)
        $appPathParts = $ApplicationPath -split "/" | Where-Object { $_ -ne "" }
        $instanceName = $appPathParts[-1]  # Get the last part
        
        # If no meaningful instance name, use a default
        if (-not $instanceName -or $instanceName -eq "Self-Service") {
            $instanceName = "Default"
        }
        
        # Simply return the IIS application alias
        return $instanceName
    }
    catch {
        return "Unknown"
    }
}

function Show-SystemInfoSummary {
    <#
    .SYNOPSIS
        Displays a concise summary of gathered system information
    .DESCRIPTION
        Shows system information with optional deployment details and disk space
    .PARAMETER SystemInfo
        System information object to display
    .PARAMETER DetectionResults
        Optional detection results for deployment information
    .PARAMETER ShowDeploymentInfo
        Whether to show ESS/WFE deployment information
    .PARAMETER ShowDiskSpace
        Whether to show disk space information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$DetectionResults = $null,
        
        [bool]$ShowDeploymentInfo = $false,
        [bool]$ShowDiskSpace = $false
    )

    Write-Host "=== System Information Summary ===" -ForegroundColor Magenta

    # Basic System Info
    Write-Host "Computer Name: $($SystemInfo.ComputerName)" -ForegroundColor White
    Write-Host "Operating System: $($SystemInfo.OS.Caption) $(if ($SystemInfo.OS.IsServer) { '(Server)' } else { '(Client)' })" -ForegroundColor White
    Write-Host "Total Memory: $($SystemInfo.Hardware.TotalPhysicalMemory) GB" -ForegroundColor White
    Write-Host "CPU Cores: $($SystemInfo.Hardware.TotalCores)" -ForegroundColor White
    Write-Host "IIS Installed: $(if ($SystemInfo.IIS.IsInstalled) { 'Yes (v' + $SystemInfo.IIS.Version + ')' } else { 'No' })" -ForegroundColor White
    
    # Optional: Show disk space for C: drive
    if ($ShowDiskSpace) {
        $cDrive = $SystemInfo.Hardware.LogicalDisks | Where-Object { $_.DeviceID -like "C*" } | Select-Object -First 1
        if ($cDrive) {
            Write-Host "Available Disk Space (C:): $($cDrive.FreeSpace) GB" -ForegroundColor White
        }
    }
    
    # Optional: Show deployment information
    if ($ShowDeploymentInfo -and $DetectionResults) {
        Write-Host "ESS Installed: $(if ($DetectionResults.ESSInstances.Count -gt 0) { 'Yes' } else { 'No' })" -ForegroundColor White
        Write-Host "WFE Installed: $(if ($DetectionResults.WFEInstances.Count -gt 0) { 'Yes' } else { 'No' })" -ForegroundColor White
        Write-Host "Deployment Type: $($DetectionResults.DeploymentType)" -ForegroundColor White
    } elseif ($ShowDeploymentInfo) {
        Write-Host "ESS Installed: Unknown" -ForegroundColor White
        Write-Host "WFE Installed: Unknown" -ForegroundColor White
        Write-Host "Deployment Type: Unknown" -ForegroundColor White
    }
    
    Write-Host "=================================" -ForegroundColor Magenta
    Write-Host ""
}

function Get-WebServerURL {
    <#
    .SYNOPSIS
        Gets the web server URL for an ESS instance
    .DESCRIPTION
        Constructs the web server URL based on the ESS instance configuration
    .PARAMETER ESSInstance
        ESS instance object containing site and application information
    .PARAMETER SystemInfo
        Optional system information for enhanced URL construction
    .RETURNS
        Web server URL string
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ESSInstance,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SystemInfo = $null
    )
    
    try {
        # Basic URL construction
        $protocol = "http"
        $hostname = $env:COMPUTERNAME
        $port = "80"
        $path = $ESSInstance.ApplicationPath
        
        # Use system info for enhanced URL if available
        if ($SystemInfo -and $SystemInfo.Network) {
            $hostname = $SystemInfo.Network.Hostname
        }
        
        # Construct URL
        $url = "$protocol" + "://" + "$hostname"
        if ($port -ne "80") {
            $url += ":" + "$port"
        }
        $url += $path
        
        return $url
    }
    catch {
        return "Unknown"
    }
}

function Test-SystemInfoAvailability {
    <#
    .SYNOPSIS
        Test if system information is available
    .DESCRIPTION
        Checks if the provided system information object is valid
    .PARAMETER SystemInfo
        System information object to validate
    .RETURNS
        Boolean indicating availability of system information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$SystemInfo = $null
    )

    if ($null -eq $SystemInfo -or $SystemInfo.Count -eq 0) {
        Write-Warning "System information is not available."
        return $false
    }

    return $true
} 