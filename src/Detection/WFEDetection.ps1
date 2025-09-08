<#
.SYNOPSIS
    WFE detection and configuration parsing
.DESCRIPTION
    Handles detection of WFE installations and parsing of WFE configuration files
.NOTES
    Author: Zoe Lai
    Date: 04/08/2025
    Version: 1.0
#>


function Find-WFEInstances {
    <#
    .SYNOPSIS
        Find all WFE installations on the machine
    #>
    [CmdletBinding()]
    param()

    try {
        $wfeInstances = @()
        
        # Import IIS modules
        try {
            Import-Module WebAdministration -ErrorAction SilentlyContinue
            Import-Module IISAdministration -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Could not import IIS modules"
            return $wfeInstances
        }

        # Get all IIS sites
        $sites = @()
        try {
            if (Get-Command "Get-IISSite" -ErrorAction SilentlyContinue) {
                $sites = Get-IISSite -ErrorAction SilentlyContinue
            }
            elseif (Get-Command "Get-Website" -ErrorAction SilentlyContinue) {
                $sites = Get-Website -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Warning "Could not retrieve IIS sites: $_"
            return $wfeInstances
        }

        foreach ($site in $sites) {
            Write-Verbose "Checking site: $($site.Name)"
            
            # Get applications in this site
            $applications = @()
            try {
                if (Get-Command "Get-IISApplication" -ErrorAction SilentlyContinue) {
                    $applications = Get-IISSite -Name $site.Name | Get-IISApplication -ErrorAction SilentlyContinue
                }
                elseif (Get-Command "Get-WebApplication" -ErrorAction SilentlyContinue) {
                    $applications = Get-WebApplication -Site $site.Name -ErrorAction SilentlyContinue
                }
            }
            catch {
                Write-Verbose "Could not get applications for site $($site.Name)"
            }

            # Check site root and all applications
            $pathsToCheck = @()
            
            # Add site root
            if ($site.PhysicalPath) {
                $pathsToCheck += @{
                    Path = $site.PhysicalPath
                    ApplicationPath = "/"
                    ApplicationPool = $site.ApplicationPool
                    IsRoot = $true
                }
            }
            
            # Add applications
            foreach ($app in $applications) {
                if ($app.PhysicalPath) {
                    $pathsToCheck += @{
                        Path = $app.PhysicalPath
                        ApplicationPath = $app.Path
                        ApplicationPool = $app.ApplicationPool
                        IsRoot = $false
                    }
                }
            }

            # Check each path for WFE installation
            foreach ($pathInfo in $pathsToCheck) {
                $physicalPath = $pathInfo.Path
                
                if ($physicalPath -and (Test-Path $physicalPath)) {
                    # Look for tenants.config
                    $tenantsConfig = Join-Path $physicalPath "tenants.config"
                    
                    if (Test-Path $tenantsConfig) {
                        Write-Verbose "Found WFE installation at: $physicalPath"
                        
                        # Parse tenants.config
                        $configInfo = Get-TenantsConfigInfo -ConfigPath $tenantsConfig
                        
                        $wfeInstance = @{
                            SiteName = $site.Name
                            PhysicalPath = $physicalPath
                            ApplicationPath = $pathInfo.ApplicationPath
                            ApplicationPool = $pathInfo.ApplicationPool
                            IsRootApplication = $pathInfo.IsRoot
                            TenantsConfigPath = $tenantsConfig
                            DatabaseServer = $configInfo.DatabaseServer
                            DatabaseName = $configInfo.DatabaseName
                            TenantID = $configInfo.TenantId
                            ClientURL = $configInfo.ClientUrl
                        }
                        
                        $wfeInstances += [PSCustomObject]$wfeInstance
                    }
                }
            }
        }

        return $wfeInstances
    }
    catch {
        Write-Warning "Error finding WFE instances: $_"
        return @()
    }
}

function Get-TenantsConfigInfo {
    <#
    .SYNOPSIS
        Parses tenants.config file to extract connection and configuration info.
    .PARAMETER ConfigPath
        Path to the tenants.config file.
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Warning "tenants.config file not found at path: $ConfigPath"
            return @{}
        }

        $configContent = Get-Content $ConfigPath -Raw
        $configInfo = @{
            DatabaseServer = $null
            DatabaseName = $null
            ClientUrl = $null
            TenantId = $null
            FromEmailAddress = $null
        }

        # Extract Connection string information
        $workflowDbMatch = [regex]::Match($configContent, '<workflowDatabaseConnection>([^<]*)</workflowDatabaseConnection>')
        if ($workflowDbMatch.Success) {
            $connectionString = $workflowDbMatch.Groups[1].Value

            # Parse the connection string
            $serverMatch = [regex]::Match($connectionString, 'data source=([^;]*)')
            if ($serverMatch.Success) {
                $configInfo.DatabaseServer = $serverMatch.Groups[1].Value.Trim()
            }

            $catalogMatch = [regex]::Match($connectionString, 'initial catalog=([^;]*)')
            if ($catalogMatch.Success) {
                $configInfo.DatabaseName = $catalogMatch.Groups[1].Value.Trim()
            }
        }

        # Extract Client URL
        $clientUrlMatch = [regex]::Match($configContent, '<clientUrl>([^<]*)</clientUrl>')
        if ($clientUrlMatch.Success) {
            $configInfo.ClientUrl = $clientUrlMatch.Groups[1].Value.Trim()
        }

        # Extract Tenant ID
        $tenantIdMatch = [regex]::Match($configContent, '<tenant id="([^"]*)">')
        if ($tenantIdMatch.Success) {
            $configInfo.TenantId = $tenantIdMatch.Groups[1].Value.Trim()
        }

        # Extract From Email Address
        $fromEmailAddressMatch = [regex]::Match($configContent, '<from-email-address>([^<]*)</from-email-address>')
        if ($fromEmailAddressMatch.Success) {
            $configInfo.FromEmailAddress = $fromEmailAddressMatch.Groups[1].Value.Trim()
        }

        return $configInfo
    }
    catch {
        Write-Warning "Error parsing tenants.config: $_"
        return @{}
    }
} 