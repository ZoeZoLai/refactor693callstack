<#
.SYNOPSIS
    Configuration settings for the ESS Health Checker
.DESCRIPTION
    Configuration that uses system information to determine appropriate settings for the ESS Health Checker based on current system.
    Following call stack principles with proper dependency injection.
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

class ESSConfiguration {
    [hashtable]$SystemInfo
    [hashtable]$DetectionResults
    [hashtable]$MinimumRequirements
    [hashtable]$ESSVersionCompatibility
    [hashtable]$ReportSettings
    [hashtable]$APIHealthCheck
    [hashtable]$Performance
    
    ESSConfiguration() {
        $this.SystemInfo = @{}
        $this.DetectionResults = @{}
        $this.MinimumRequirements = @{}
        $this.ESSVersionCompatibility = @{}
        $this.ReportSettings = @{}
        $this.APIHealthCheck = @{}
        $this.Performance = @{}
    }
}

# Global configuration instance
$script:ESSConfig = $null

function Initialize-ESSConfiguration {
    <#
    .SYNOPSIS
        Initializes ESS Health Checker configuration based on current system info
    .DESCRIPTION
        Determines configuration for both ESS and WFE components using dependency injection
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$SystemInfo = $null,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$DetectionResults = $null
    )

    try {
        Write-Verbose "Initializing Health Checker configuration based on system information..."

        # Create new configuration instance
        $script:ESSConfig = [ESSConfiguration]::new()
        
        # Set system information if provided
        if ($SystemInfo) {
            $script:ESSConfig.SystemInfo = $SystemInfo
        }
        
        # Set detection results if provided
        if ($DetectionResults) {
            $script:ESSConfig.DetectionResults = $DetectionResults
        }

        # Set minimum requirements
        $script:ESSConfig.MinimumRequirements = @{
            MinimumDiskSpaceGB = Get-MinimumDiskSpace
            MinimumMemoryGB = Get-MinimumMemory
            MinimumCores = Get-MinimumCores
            MinimumProcessorSpeedGHz = Get-MinimumProcessorSpeed
            RequiredOSVersions = @("Windows Server 2016", "Windows Server 2019", "Windows Server 2022")
            RequiredDotNetVersion = "4.8"
            RequiredIISVersion = "7.5"
            MinimumESSVersion = "5.4.7.2"
        }

        # Set ESS Version Compatibility
        $script:ESSConfig.ESSVersionCompatibility = @{
            "5.5.1.2" = @{
                MinimumPayGlobalVersion = "4.66.0.0"
                Description = "ESS 5.5.1.2 requires PayGlobal 4.66.0.0 or higher"
            }
            "5.6.0.0" = @{
                MinimumPayGlobalVersion = "4.72.0.0"
                Description = "ESS 5.6.0.0 requires PayGlobal 4.72.0.0 or higher"
            }
        }

        # Set report settings
        $script:ESSConfig.ReportSettings = @{
            ReportOutputPath = Get-ReportOutputPath
            ReportNameFormat = "ESS_PreUpgrade_HealthCheck_{0:yyyyMMdd_HHmmss}.html"
        }

        # Set API Health Check Settings
        $script:ESSConfig.APIHealthCheck = @{
            DefaultTimeoutSeconds = 90
            MaxRetries = 2
            RetryDelaySeconds = 5
            ConnectionTimeoutSeconds = 30
            ReadWriteTimeoutSeconds = 60
        }

        # Set Performance and Reliability Settings
        $script:ESSConfig.Performance = @{
            EnableRetryLogic = $true
            EnableConnectionPooling = $true
            MaxConcurrentRequests = 3
            RequestDelaySeconds = 1
        }

        Write-Verbose "ESS Health Checker configuration initialized successfully."
        return $script:ESSConfig
    }
    catch {
        Write-Error "Error initializing ESS Health Checker configuration: $_"
        throw
    }
}

function Get-ESSConfiguration {
    <#
    .SYNOPSIS
        Gets the current ESS configuration
    .DESCRIPTION
        Returns the singleton ESS configuration instance
    #>
    [CmdletBinding()]
    param()
    
    if ($null -eq $script:ESSConfig) {
        Initialize-ESSConfiguration
    }
    
    return $script:ESSConfig
}

function Update-ESSConfiguration {
    <#
    .SYNOPSIS
        Updates the ESS configuration with new data
    .DESCRIPTION
        Updates specific parts of the configuration with new information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$SystemInfo = $null,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$DetectionResults = $null
    )
    
    $config = Get-ESSConfiguration
    
    if ($SystemInfo) {
        $config.SystemInfo = $SystemInfo
    }
    
    if ($DetectionResults) {
        $config.DetectionResults = $DetectionResults
    }
    
    Write-Verbose "ESS configuration updated"
}

function Get-ReportOutputPath {
    <#
    .SYNOPSIS
        Determines report output path
    #>
    param()

    # Use temp path
    if ($env:TEMP) {
        return Join-Path $env:TEMP "ESSHealthCheckReports"
    }

    # Fallback to use user profile
    return "$env:USERPROFILE\ESSHealthCheckReports"
}

function Get-MinimumDiskSpace {
    <#
    .SYNOPSIS
        Returns MYOB PayGlobal ESS Web server or Workflow Engine Server recommended minimum disk space requirement
    #>
    param()
    return 10  # MYOB PayGlobal suggested minimum disk space to alert (GB) for PG Server ESS alert 10 GB
}

function Get-MinimumMemory {
    <#
    .SYNOPSIS
        Returns MYOB PayGlobal ESS Web server or Workflow Engine Server recommended minimum memory requirement
    #>
    param()
    return 32  # MYOB PayGlobal ESS recommended minimum RAM (GB)
}

function Get-MinimumCores {
    <#
    .SYNOPSIS
        Returns MYOB PayGlobal ESS Web server or Workflow Engine Server recommended minimum CPU cores requirement
    #>
    param()
    return 4  # MYOB PayGlobal ESS recommended minimum CPU cores (2 x Multi-Core Server Processor 2.0GHz+)
}

function Get-MinimumProcessorSpeed {
    <#
    .SYNOPSIS
        Returns MYOB PayGlobal ESS Web server or Workflow Engine Server recommended minimum processor speed requirement
    #>
    param()
    return 2.0  # MYOB PayGlobal ESS recommended minimum processor speed (GHz)
}

# Initialize configuration when module is loaded
Initialize-ESSConfiguration

