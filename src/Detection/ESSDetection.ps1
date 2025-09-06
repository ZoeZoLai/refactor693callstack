<#
.SYNOPSIS
    Consolidated ESS and WFE detection module
.DESCRIPTION
    Handles detection of ESS and WFE installations and parsing of configuration files
.NOTES
    Author: Zoe Lai
    Date: 23/08/2025
    Version: 2.0 - Simplified Structure
#>

function Test-ESSInstallation {
    <#
    .SYNOPSIS
        Test if ESS is installed on current server via IIS discovery.
    .DESCRIPTION
        Discovers ESS installation by checking IIS sites and payglobal.config file.
    #>
    
    try {
        Write-Verbose "Starting ESS installation check..."
        
        # Check if IIS is installed first
        $iisInstalled = $false
        try {
            if (Get-Command "Get-WindowsFeature" -ErrorAction SilentlyContinue) {
                $webServerFeature = Get-WindowsFeature -Name "Web-Server" -ErrorAction SilentlyContinue
                $iisInstalled = $webServerFeature -and $webServerFeature.InstallState -eq "Installed"
            }
        }
        catch {
            # Try registry method for IIS detection
            $iisRegKey = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp" -ErrorAction SilentlyContinue
            $iisInstalled = $null -ne $iisRegKey
        }
        
        # Additional check for IIS installation via service
        if (-not $iisInstalled) {
            try {
                $w3svcService = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
                $iisInstalled = $w3svcService -and $w3svcService.Status -eq "Running"
            }
            catch {
                # Service check failed, continue
            }
        }
        
        Write-Verbose "IIS installed: $iisInstalled"
        
        # Check for ESS sites in IIS
        if ($iisInstalled) {
            # Import IIS module if available
            try {
                Import-Module WebAdministration -ErrorAction SilentlyContinue
                Import-Module IISAdministration -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Could not import IIS modules, trying alternative methods"
            }
            
            # Get sites using multiple methods
            $sites = @()
            try {
                # Try IISAdministration module first
                if (Get-Command "Get-IISSite" -ErrorAction SilentlyContinue) {
                    $sites = Get-IISSite -ErrorAction SilentlyContinue
                    Write-Verbose "Found $($sites.Count) sites using Get-IISSite"
                }
                # Fallback to WebAdministration module
                elseif (Get-Command "Get-Website" -ErrorAction SilentlyContinue) {
                    $sites = Get-Website -ErrorAction SilentlyContinue
                    Write-Verbose "Found $($sites.Count) sites using Get-Website"
                }
            }
            catch {
                if ($_.Exception.Message -like "*insufficient permissions*" -or $_.Exception.Message -like "*redirection.config*") {
                    Write-Warning "Could not retrieve IIS sites due to insufficient permissions. Run as Administrator to access IIS configuration."
                } else {
                    Write-Warning "Could not retrieve IIS sites: $_"
                }
            }
            
            foreach ($site in $sites) {
                Write-Verbose "Checking IIS site for ESS: $($site.Name)"

                # Get all applications in this site using multiple methods
                $siteApplications = @()
                try {
                    if (Get-Command "Get-IISApplication" -ErrorAction SilentlyContinue) {
                        $siteApplications = Get-IISSite -Name $site.Name | Get-IISApplication -ErrorAction SilentlyContinue
                    }
                    elseif (Get-Command "Get-WebApplication" -ErrorAction SilentlyContinue) {
                        $siteApplications = Get-WebApplication -Site $site.Name -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Verbose "Could not get applications for site $($site.Name): $_"
                }

                # Check both site root and applications within the site
                $allPathsToCheck = @()
                
                # Add site root path
                if ($site.PhysicalPath) {
                    $allPathsToCheck += @{
                        Path = $site.PhysicalPath
                        ApplicationPath = "/"
                        ApplicationPool = $site.ApplicationPool
                        IsRoot = $true
                    }
                }
                
                # Add application paths
                foreach ($app in $siteApplications) {
                    if ($app.PhysicalPath) {
                        $allPathsToCheck += @{
                            Path = $app.PhysicalPath
                            ApplicationPath = $app.Path
                            ApplicationPool = $app.ApplicationPool
                            IsRoot = $false
                        }
                    }
                }
                
                # Check each path for ESS installation
                foreach ($pathInfo in $allPathsToCheck) {
                    $physicalPath = $pathInfo.Path
                    
                    if ($physicalPath -and (Test-Path $physicalPath)) {
                        # Look for payglobal.config
                        $payglobalConfig = Join-Path $physicalPath "payglobal.config"
                        
                        if (Test-Path $payglobalConfig) {
                            Write-Verbose "Found ESS installation at: $physicalPath"
                            
                            # Get web.config path for encryption checking
                            $webConfigPath = Join-Path $physicalPath "Web.config"
                            
                            # Parse payglobal.config
                            $configInfo = Get-PayGlobalConfigInfo -ConfigPath $payglobalConfig -WebConfigPath $webConfigPath
                            
                            # Get version information from bin folder
                            $binPath = Join-Path $physicalPath "bin"
                            $versionInfo = Get-ESSVersionInfo -BinPath $binPath
                            
                            # Test version compatibility
                            $compatibilityInfo = Test-ESSVersionCompatibility -ESSVersion $versionInfo.ESSVersion -PayGlobalVersion $versionInfo.PayGlobalVersion
                            
                            return @{
                                Installed = $true
                                InstallPath = $physicalPath
                                WebConfigPath = Join-Path $physicalPath "Web.config"
                                BinPath = Join-Path $physicalPath "bin"
                                PayGlobalConfigPath = $payglobalConfig
                                SiteName = $site.Name
                                ApplicationPath = $pathInfo.ApplicationPath
                                ApplicationPool = $pathInfo.ApplicationPool
                                DatabaseServer = $configInfo.DatabaseServer
                                DatabaseName = $configInfo.DatabaseName
                                TenantID = $configInfo.TenantID
                                HostName = $configInfo.HostName
                                VirtualRoot = $configInfo.VirtualRoot
                                Protocol = $configInfo.Protocol
                                AuthenticationMode = $configInfo.AuthenticationMode
                                WebConfigEncrypted = $configInfo.WebConfigEncrypted
                                EncryptionStatus = $configInfo.EncryptionStatus
                                ESSVersion = $versionInfo.ESSVersion
                                PayGlobalVersion = $versionInfo.PayGlobalVersion
                                VersionCompatibility = $compatibilityInfo
                            }
                        }
                    }
                }
            }
        }
        
        # if no ESS found via IIS, it might be installed on other server
        Write-Verbose "No ESS installation found in IIS - ESS may not be installed on this server."
        return @{
            Installed = $false
            InstallPath = $null
            WebConfigPath = $null
            BinPath = $null
            PayGlobalConfigPath = $null
            SiteName = $null
            ApplicationPath = $null
            ApplicationPool = $null
            DatabaseServer = $null
            DatabaseName = $null
            TenantID = $null
            HostName = $null
            VirtualRoot = $null
            Protocol = "null"
            AuthenticationMode = $null
        }
        
    }
    catch {
        Write-Warning "Error checking ESS installation: $_"
        return @{
            Installed = $false
            InstallPath = $null
            WebConfigPath = $null
            BinPath = $null
            PayGlobalConfigPath = $null
            SiteName = $null
            ApplicationPath = $null
            ApplicationPool = $null
            DatabaseServer = $null
            DatabaseName = $null
            TenantID = $null
            HostName = $null
            VirtualRoot = $null
            Protocol = "null"
            AuthenticationMode = $null
        }
    }
}

function Test-WFEInstallation {
    <#
    .SYNOPSIS
        Test if WFE is installed on current server via IIS discovery.
    .DESCRIPTION
        Discovers WFE installation by checking IIS sites and looking for tenants.config file.
    #>

    try {
        Write-Verbose "Starting WFE installation check..."
        
        # Check if IIS is installed first
        $iisInstalled = $false
        try {
            if (Get-Command "Get-WindowsFeature" -ErrorAction SilentlyContinue) {
                $webServerFeature = Get-WindowsFeature -Name "Web-Server" -ErrorAction SilentlyContinue
                $iisInstalled = $webServerFeature -and $webServerFeature.InstallState -eq "Installed"
            }
        }
        catch {
            # Try registry method for IIS detection
            $iisRegKey = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp" -ErrorAction SilentlyContinue
            $iisInstalled = $null -ne $iisRegKey
        }
        
        # Additional check for IIS installation via service
        if (-not $iisInstalled) {
            try {
                $w3svcService = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
                $iisInstalled = $w3svcService -and $w3svcService.Status -eq "Running"
            }
            catch {
                # Service check failed, continue
            }
        }
        
        Write-Verbose "IIS installed: $iisInstalled"
        
        # Check for WFE sites in IIS
        if ($iisInstalled) {
            # Import IIS module if available
            try {
                Import-Module WebAdministration -ErrorAction SilentlyContinue
                Import-Module IISAdministration -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Could not import IIS modules, trying alternative methods"
            }
            
            # Get sites using multiple methods
            $sites = @()
            try {
                # Try IISAdministration module first
                if (Get-Command "Get-IISSite" -ErrorAction SilentlyContinue) {
                    $sites = Get-IISSite -ErrorAction SilentlyContinue
                    Write-Verbose "Found $($sites.Count) sites using Get-IISSite"
                }
                # Fallback to WebAdministration module
                elseif (Get-Command "Get-Website" -ErrorAction SilentlyContinue) {
                    $sites = Get-Website -ErrorAction SilentlyContinue
                    Write-Verbose "Found $($sites.Count) sites using Get-Website"
                }
            }
            catch {
                if ($_.Exception.Message -like "*insufficient permissions*" -or $_.Exception.Message -like "*redirection.config*") {
                    Write-Warning "Could not retrieve IIS sites due to insufficient permissions. Run as Administrator to access IIS configuration."
                } else {
                    Write-Warning "Could not retrieve IIS sites: $_"
                }
            }
            
            foreach ($site in $sites) {
                Write-Verbose "Checking IIS site for WFE: $($site.Name)"

                # Get all applications in this site using multiple methods
                $siteApplications = @()
                try {
                    if (Get-Command "Get-IISApplication" -ErrorAction SilentlyContinue) {
                        $siteApplications = Get-IISSite -Name $site.Name | Get-IISApplication -ErrorAction SilentlyContinue
                    }
                    elseif (Get-Command "Get-WebApplication" -ErrorAction SilentlyContinue) {
                        $siteApplications = Get-WebApplication -Site $site.Name -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Verbose "Could not get applications for site $($site.Name): $_"
                }

                # Check both site root and applications within the site
                $allPathsToCheck = @()
                
                # Add site root path
                if ($site.PhysicalPath) {
                    $allPathsToCheck += @{
                        Path = $site.PhysicalPath
                        ApplicationPath = "/"
                        ApplicationPool = $site.ApplicationPool
                        IsRoot = $true
                    }
                }
                
                # Add application paths
                foreach ($app in $siteApplications) {
                    if ($app.PhysicalPath) {
                        $allPathsToCheck += @{
                            Path = $app.PhysicalPath
                            ApplicationPath = $app.Path
                            ApplicationPool = $app.ApplicationPool
                            IsRoot = $false
                        }
                    }
                }
                
                # Check each path for WFE installation
                foreach ($pathInfo in $allPathsToCheck) {
                    $physicalPath = $pathInfo.Path
                    
                    if ($physicalPath -and (Test-Path $physicalPath)) {
                        # Look for tenants.config
                        $tenantsConfig = Join-Path $physicalPath "tenants.config"
                        
                        if (Test-Path $tenantsConfig) {
                            Write-Verbose "Found WFE installation at: $physicalPath"
                            
                            # Get web.config path for encryption checking
                            $webConfigPath = Join-Path $physicalPath "Web.config"
                            
                            # Parse tenants.config
                            $configInfo = Get-TenantsConfigInfo -ConfigPath $tenantsConfig -WebConfigPath $webConfigPath
                            
                            # Get version information from bin folder
                            $binPath = Join-Path $physicalPath "bin"
                            $versionInfo = Get-WFEVersionInfo -BinPath $binPath
                            
                            return @{
                                Installed = $true
                                InstallPath = $physicalPath
                                WebConfigPath = Join-Path $physicalPath "Web.config"
                                BinPath = Join-Path $physicalPath "bin"
                                TenantsConfigPath = $tenantsConfig
                                SiteName = $site.Name
                                ApplicationPath = $pathInfo.ApplicationPath
                                ApplicationPool = $pathInfo.ApplicationPool
                                DatabaseServer = $configInfo.DatabaseServer
                                DatabaseName = $configInfo.DatabaseName
                                HostName = $configInfo.HostName
                                VirtualRoot = $configInfo.VirtualRoot
                                Protocol = $configInfo.Protocol
                                AuthenticationMode = $configInfo.AuthenticationMode
                                WebConfigEncrypted = $configInfo.WebConfigEncrypted
                                EncryptionStatus = $configInfo.EncryptionStatus
                                WFEVersion = $versionInfo.WFEVersion
                                PayGlobalVersion = $versionInfo.PayGlobalVersion
                            }
                        }
                    }
                }
            }
        }
        
        # if no WFE found via IIS, it might be installed on other server
        Write-Verbose "No WFE installation found in IIS - WFE may not be installed on this server."
        return @{
            Installed = $false
            InstallPath = $null
            WebConfigPath = $null
            BinPath = $null
            TenantsConfigPath = $null
            SiteName = $null
            ApplicationPath = $null
            ApplicationPool = $null
            DatabaseServer = $null
            DatabaseName = $null
            HostName = $null
            VirtualRoot = $null
            Protocol = "null"
            AuthenticationMode = $null
        }
        
    }
    catch {
        Write-Warning "Error checking WFE installation: $_"
        return @{
            Installed = $false
            InstallPath = $null
            WebConfigPath = $null
            BinPath = $null
            TenantsConfigPath = $null
            SiteName = $null
            ApplicationPath = $null
            ApplicationPool = $null
            DatabaseServer = $null
            DatabaseName = $null
            HostName = $null
            VirtualRoot = $null
            Protocol = "null"
            AuthenticationMode = $null
        }
    }
}

function Get-ESSWFEDetection {
    <#
    .SYNOPSIS
        Gets comprehensive ESS and WFE detection results
    .DESCRIPTION
        Detects both ESS and WFE installations and returns consolidated results
    .PARAMETER SystemInfo
        System information object
    .RETURNS
        Hashtable containing detection results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo
    )
    
    try {
        Write-Host "Detecting ESS and WFE installations..." -ForegroundColor Yellow
        
        # Detect ESS installations
        $essResults = Test-ESSInstallation
        
        # Detect WFE installations
        $wfeResults = Test-WFEInstallation
        
        # Determine deployment type
        $deploymentType = "Unknown"
        if ($essResults.Installed -and $wfeResults.Installed) {
            $deploymentType = "Combined ESS/WFE"
        } elseif ($essResults.Installed) {
            $deploymentType = "ESS Only"
        } elseif ($wfeResults.Installed) {
            $deploymentType = "WFE Only"
        } else {
            $deploymentType = "No ESS/WFE Detected"
        }
        
        $detectionResults = @{
            DeploymentType = $deploymentType
            ESSInstances = if ($essResults.Installed) { @($essResults) } else { @() }
            WFEInstances = if ($wfeResults.Installed) { @($wfeResults) } else { @() }
            TotalESSInstances = if ($essResults.Installed) { 1 } else { 0 }
            TotalWFEInstances = if ($wfeResults.Installed) { 1 } else { 0 }
            DetectionTimestamp = Get-Date
        }
        
        Write-Host "Detection completed successfully" -ForegroundColor Green
        Write-Host "Deployment Type: $deploymentType" -ForegroundColor Cyan
        
        return $detectionResults
    }
    catch {
        Write-Error "Failed to detect ESS/WFE installations: $_"
        throw
    }
}

# Helper functions for configuration parsing (simplified versions)
function Get-PayGlobalConfigInfo {
    param($ConfigPath, $WebConfigPath)
    # Simplified implementation - return basic structure
    return @{
        DatabaseServer = "Unknown"
        DatabaseName = "Unknown"
        TenantID = "Unknown"
        HostName = "Unknown"
        VirtualRoot = "Unknown"
        Protocol = "Unknown"
        AuthenticationMode = "Unknown"
        WebConfigEncrypted = $false
        EncryptionStatus = "Unknown"
    }
}

function Get-ESSVersionInfo {
    param($BinPath)
    # Simplified implementation - return basic structure
    return @{
        ESSVersion = "Unknown"
        PayGlobalVersion = "Unknown"
    }
}

function Test-ESSVersionCompatibility {
    param($ESSVersion, $PayGlobalVersion)
    # Simplified implementation
    return @{
        Compatible = $true
        Message = "Version compatibility check not implemented"
    }
}

function Get-TenantsConfigInfo {
    param($ConfigPath, $WebConfigPath)
    # Simplified implementation - return basic structure
    return @{
        DatabaseServer = "Unknown"
        DatabaseName = "Unknown"
        HostName = "Unknown"
        VirtualRoot = "Unknown"
        Protocol = "Unknown"
        AuthenticationMode = "Unknown"
        WebConfigEncrypted = $false
        EncryptionStatus = "Unknown"
    }
}

function Get-WFEVersionInfo {
    param($BinPath)
    # Simplified implementation - return basic structure
    return @{
        WFEVersion = "Unknown"
        PayGlobalVersion = "Unknown"
    }
}
