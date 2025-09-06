<#
.SYNOPSIS
    Consolidated system validation module
.DESCRIPTION
    Validates system requirements, infrastructure, and ESS-specific requirements
.NOTES
    Author: Zoe Lai
    Date: 23/08/2025
    Version: 2.0 - Simplified Structure
#>

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Tests system requirements for ESS upgrade
    .DESCRIPTION
        Validates system requirements using injected dependencies
    .PARAMETER SystemInfo
        System information object containing hardware, OS, and software details
    .PARAMETER Configuration
        Optional configuration object containing minimum requirements
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = $null
    )

    Write-Verbose "Testing system requirements..."
    
    # Use provided configuration or get default values
    $config = if ($Configuration) { $Configuration } else { Get-ESSConfiguration }
    
    # Test disk space
    $cDrive = $SystemInfo.Hardware.LogicalDisks | Where-Object { $_.DeviceID -eq "C:" } | Select-Object -First 1
    if ($cDrive) {
        $diskSpaceGB = $cDrive.Size
        $freeSpaceGB = $cDrive.FreeSpace
        $requiredDiskSpace = $config.MinimumRequirements.MinimumDiskSpaceGB
        
        if ($freeSpaceGB -lt $requiredDiskSpace) {
            Add-HealthCheckResult -Category "System Requirements" -Check "Free Disk Space" -Status "FAIL" -Message "Insufficient disk space. Available: $freeSpaceGB (Total: $diskSpaceGB) GB - Required: $requiredDiskSpace GB"
        } else {
            Add-HealthCheckResult -Category "System Requirements" -Check "Free Disk Space" -Status "PASS" -Message "Sufficient disk space available. Available: $freeSpaceGB (Total: $diskSpaceGB) GB - meets requirement of $requiredDiskSpace GB"
        }
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "Free Disk Space" -Status "WARNING" -Message "Could not determine disk space"
    }
    
    # Test memory
    $totalMemory = $SystemInfo.Hardware.TotalPhysicalMemory
    $requiredMemory = $config.MinimumRequirements.MinimumMemoryGB
    
    if ($totalMemory -lt $requiredMemory) {
        Add-HealthCheckResult -Category "System Requirements" -Check "Memory" -Status "FAIL" -Message "Insufficient memory. Available: $totalMemory GB - Required: $requiredMemory GB"
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "Memory" -Status "PASS" -Message "Sufficient memory available. Available: $totalMemory GB - meets requirement of $requiredMemory GB"
    }
    
    # Test CPU cores
    $totalCores = $SystemInfo.Hardware.TotalCores
    $requiredCores = $config.MinimumRequirements.MinimumCores
    
    if ($totalCores -lt $requiredCores) {
        Add-HealthCheckResult -Category "System Requirements" -Check "CPU Cores" -Status "FAIL" -Message "Insufficient CPU cores. Available: $totalCores - Required: $requiredCores"
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "CPU Cores" -Status "PASS" -Message "Sufficient CPU cores available. Available: $totalCores - meets requirement of $requiredCores"
    }
    
    # Test processor speed
    $averageProcessorSpeed = $SystemInfo.Hardware.AverageProcessorSpeedGHz
    $requiredProcessorSpeed = $config.MinimumRequirements.MinimumProcessorSpeedGHz
    
    if ($averageProcessorSpeed -lt $requiredProcessorSpeed) {
        Add-HealthCheckResult -Category "System Requirements" -Check "Processor Speed" -Status "FAIL" -Message "Insufficient processor speed. Available: $averageProcessorSpeed GHz - Required: $requiredProcessorSpeed GHz"
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "Processor Speed" -Status "PASS" -Message "Sufficient processor speed available. Available: $averageProcessorSpeed GHz - meets requirement of $requiredProcessorSpeed GHz"
    }
    
    # Test IIS installation and version
    if ($SystemInfo.IIS.IsInstalled) {
        $iisVersion = $SystemInfo.IIS.Version
        $requiredIISVersion = $config.MinimumRequirements.RequiredIISVersion
        
        # Parse version numbers for comparison
        $iisVersionParts = $iisVersion.Split('.')
        $requiredVersionParts = $requiredIISVersion.Split('.')
        
        $iisVersionNum = [double]"$($iisVersionParts[0]).$($iisVersionParts[1])"
        $requiredVersionNum = [double]"$($requiredVersionParts[0]).$($requiredVersionParts[1])"
        
        if ($iisVersionNum -ge $requiredVersionNum) {
            Add-HealthCheckResult -Category "System Requirements" -Check "IIS Installation" -Status "PASS" -Message "IIS is installed (Version: $iisVersion) - meets minimum requirement of $requiredIISVersion"
        } else {
            Add-HealthCheckResult -Category "System Requirements" -Check "IIS Installation" -Status "FAIL" -Message "IIS version $iisVersion is below minimum requirement of $requiredIISVersion"
        }
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "IIS Installation" -Status "FAIL" -Message "IIS is not installed - required for ESS"
    }
    
    # Test .NET Framework
    $dotNetVersions = $SystemInfo.Registry.DotNetVersions
    $requiredDotNetVersion = $config.MinimumRequirements.RequiredDotNetVersion
    
    if ($dotNetVersions -and $dotNetVersions.Count -gt 0) {
        $highestVersion = $dotNetVersions | Sort-Object -Descending | Select-Object -First 1
        
        # Simple version comparison for .NET Framework
        if ($highestVersion -ge $requiredDotNetVersion) {
            Add-HealthCheckResult -Category "System Requirements" -Check ".NET Framework" -Status "PASS" -Message ".NET Framework $highestVersion is installed - meets minimum requirement of $requiredDotNetVersion"
        } else {
            Add-HealthCheckResult -Category "System Requirements" -Check ".NET Framework" -Status "FAIL" -Message ".NET Framework $highestVersion is below minimum requirement of $requiredDotNetVersion"
        }
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check ".NET Framework" -Status "FAIL" -Message ".NET Framework is not installed - required for ESS"
    }
    
    # Test SQL Server
    if ($SystemInfo.SQL.IsInstalled) {
        Add-HealthCheckResult -Category "System Requirements" -Check "SQL Server" -Status "PASS" -Message "SQL Server is installed - required for ESS database"
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "SQL Server" -Status "WARNING" -Message "SQL Server is not installed - may be required for ESS database"
    }
    
    Write-Verbose "System requirements validation completed"
}

function Test-InfrastructureValidation {
    <#
    .SYNOPSIS
        Tests infrastructure requirements
    .DESCRIPTION
        Validates infrastructure components and connectivity
    .PARAMETER SystemInfo
        System information object
    .PARAMETER DetectionResults
        Detection results object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults
    )
    
    Write-Verbose "Testing infrastructure validation..."
    
    # Test network connectivity
    if ($SystemInfo.Network.NetworkAdapters -and $SystemInfo.Network.NetworkAdapters.Count -gt 0) {
        $activeAdapters = $SystemInfo.Network.NetworkAdapters | Where-Object { $_.Status -eq "Up" }
        if ($activeAdapters.Count -gt 0) {
            Add-HealthCheckResult -Category "Infrastructure" -Check "Network Adapters" -Status "PASS" -Message "Active network adapters found: $($activeAdapters.Count)"
        } else {
            Add-HealthCheckResult -Category "Infrastructure" -Check "Network Adapters" -Status "FAIL" -Message "No active network adapters found"
        }
    } else {
        Add-HealthCheckResult -Category "Infrastructure" -Check "Network Adapters" -Status "WARNING" -Message "Could not determine network adapter status"
    }
    
    # Test IIS sites and applications
    if ($SystemInfo.IIS.IsInstalled) {
        if ($SystemInfo.IIS.TotalSites -gt 0) {
            Add-HealthCheckResult -Category "Infrastructure" -Check "IIS Sites" -Status "PASS" -Message "IIS sites found: $($SystemInfo.IIS.TotalSites)"
        } else {
            Add-HealthCheckResult -Category "Infrastructure" -Check "IIS Sites" -Status "WARNING" -Message "No IIS sites found"
        }
        
        if ($SystemInfo.IIS.TotalApplications -gt 0) {
            Add-HealthCheckResult -Category "Infrastructure" -Check "IIS Applications" -Status "PASS" -Message "IIS applications found: $($SystemInfo.IIS.TotalApplications)"
        } else {
            Add-HealthCheckResult -Category "Infrastructure" -Check "IIS Applications" -Status "INFO" -Message "No IIS applications found"
        }
    }
    
    # Test ESS/WFE deployment
    if ($DetectionResults.DeploymentType -ne "No ESS/WFE Detected") {
        Add-HealthCheckResult -Category "Infrastructure" -Check "ESS/WFE Deployment" -Status "PASS" -Message "ESS/WFE deployment detected: $($DetectionResults.DeploymentType)"
        
        if ($DetectionResults.TotalESSInstances -gt 0) {
            Add-HealthCheckResult -Category "Infrastructure" -Check "ESS Instances" -Status "PASS" -Message "ESS instances found: $($DetectionResults.TotalESSInstances)"
        }
        
        if ($DetectionResults.TotalWFEInstances -gt 0) {
            Add-HealthCheckResult -Category "Infrastructure" -Check "WFE Instances" -Status "PASS" -Message "WFE instances found: $($DetectionResults.TotalWFEInstances)"
        }
    } else {
        Add-HealthCheckResult -Category "Infrastructure" -Check "ESS/WFE Deployment" -Status "WARNING" -Message "No ESS/WFE deployment detected on this server"
    }
    
    Write-Verbose "Infrastructure validation completed"
}

function Test-ESSValidation {
    <#
    .SYNOPSIS
        Tests ESS-specific validation
    .DESCRIPTION
        Validates ESS-specific requirements and configurations
    .PARAMETER SystemInfo
        System information object
    .PARAMETER DetectionResults
        Detection results object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults
    )
    
    Write-Verbose "Testing ESS-specific validation..."
    
    # Test ESS installation
    if ($DetectionResults.TotalESSInstances -gt 0) {
        foreach ($essInstance in $DetectionResults.ESSInstances) {
            if ($essInstance.Installed) {
                Add-HealthCheckResult -Category "ESS Validation" -Check "ESS Installation" -Status "PASS" -Message "ESS installation found at: $($essInstance.InstallPath)"
                
                # Test ESS version
                if ($essInstance.ESSVersion -and $essInstance.ESSVersion -ne "Unknown") {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "ESS Version" -Status "PASS" -Message "ESS version: $($essInstance.ESSVersion)"
                } else {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "ESS Version" -Status "WARNING" -Message "Could not determine ESS version"
                }
                
                # Test PayGlobal version
                if ($essInstance.PayGlobalVersion -and $essInstance.PayGlobalVersion -ne "Unknown") {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "PayGlobal Version" -Status "PASS" -Message "PayGlobal version: $($essInstance.PayGlobalVersion)"
                } else {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "PayGlobal Version" -Status "WARNING" -Message "Could not determine PayGlobal version"
                }
                
                # Test configuration files
                if (Test-Path $essInstance.PayGlobalConfigPath) {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "PayGlobal Config" -Status "PASS" -Message "PayGlobal configuration file found"
                } else {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "PayGlobal Config" -Status "FAIL" -Message "PayGlobal configuration file not found"
                }
                
                if (Test-Path $essInstance.WebConfigPath) {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "Web Config" -Status "PASS" -Message "Web configuration file found"
                } else {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "Web Config" -Status "FAIL" -Message "Web configuration file not found"
                }
            }
        }
    } else {
        Add-HealthCheckResult -Category "ESS Validation" -Check "ESS Installation" -Status "WARNING" -Message "No ESS installation detected"
    }
    
    # Test WFE installation
    if ($DetectionResults.TotalWFEInstances -gt 0) {
        foreach ($wfeInstance in $DetectionResults.WFEInstances) {
            if ($wfeInstance.Installed) {
                Add-HealthCheckResult -Category "ESS Validation" -Check "WFE Installation" -Status "PASS" -Message "WFE installation found at: $($wfeInstance.InstallPath)"
                
                # Test WFE version
                if ($wfeInstance.WFEVersion -and $wfeInstance.WFEVersion -ne "Unknown") {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "WFE Version" -Status "PASS" -Message "WFE version: $($wfeInstance.WFEVersion)"
                } else {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "WFE Version" -Status "WARNING" -Message "Could not determine WFE version"
                }
                
                # Test configuration files
                if (Test-Path $wfeInstance.TenantsConfigPath) {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "Tenants Config" -Status "PASS" -Message "Tenants configuration file found"
                } else {
                    Add-HealthCheckResult -Category "ESS Validation" -Check "Tenants Config" -Status "FAIL" -Message "Tenants configuration file not found"
                }
            }
        }
    } else {
        Add-HealthCheckResult -Category "ESS Validation" -Check "WFE Installation" -Status "INFO" -Message "No WFE installation detected"
    }
    
    Write-Verbose "ESS-specific validation completed"
}

function Start-SystemValidation {
    <#
    .SYNOPSIS
        Starts comprehensive system validation
    .DESCRIPTION
        Runs all validation checks including system requirements, infrastructure, and ESS-specific validation
    .PARAMETER SystemInfo
        System information object
    .PARAMETER DetectionResults
        Detection results object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults
    )
    
    try {
        Write-Host "Running system validation..." -ForegroundColor Yellow
        
        # Run all validation checks
        Test-SystemRequirements -SystemInfo $SystemInfo
        Test-InfrastructureValidation -SystemInfo $SystemInfo -DetectionResults $DetectionResults
        Test-ESSValidation -SystemInfo $SystemInfo -DetectionResults $DetectionResults
        
        Write-Host "System validation completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to run system validation: $_"
        throw
    }
}
