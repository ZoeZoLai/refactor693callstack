<#
.SYNOPSIS
    System requirements validation module
.DESCRIPTION
    Validates system requirements for ESS upgrade including hardware, OS, and software requirements
    Following call stack principles with dependency injection
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Tests system requirements for ESS upgrade
    .DESCRIPTION
        Validates system requirements using injected dependencies
    .PARAMETER SystemInfo
        System information object containing hardware, OS, and software details
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    .PARAMETER Configuration
        Optional configuration object containing minimum requirements
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager,
        
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
            Add-HealthCheckResult -Category "System Requirements" -Check "Free Disk Space" -Status "FAIL" -Message "Insufficient disk space. Available: $freeSpaceGB (Total: $diskSpaceGB) GB - Required: $requiredDiskSpace GB" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "System Requirements" -Check "Free Disk Space" -Status "PASS" -Message "Sufficient disk space available. Available: $freeSpaceGB (Total: $diskSpaceGB) GB - meets requirement of $requiredDiskSpace GB" -Manager $Manager
        }
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "Free Disk Space" -Status "WARNING" -Message "Could not determine disk space" -Manager $Manager
    }
    
    # Test memory
    $totalMemory = $SystemInfo.Hardware.TotalPhysicalMemory
    $requiredMemory = $config.MinimumRequirements.MinimumMemoryGB
    
    if ($totalMemory -lt $requiredMemory) {
        Add-HealthCheckResult -Category "System Requirements" -Check "Memory" -Status "FAIL" -Message "Insufficient memory. Available: $totalMemory GB - Required: $requiredMemory GB" -Manager $Manager
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "Memory" -Status "PASS" -Message "Sufficient memory available. Available: $totalMemory GB - meets requirement of $requiredMemory GB" -Manager $Manager
    }
    
    # Test CPU cores
    $totalCores = $SystemInfo.Hardware.TotalCores
    $requiredCores = $config.MinimumRequirements.MinimumCores
    
    if ($totalCores -lt $requiredCores) {
        Add-HealthCheckResult -Category "System Requirements" -Check "CPU Cores" -Status "FAIL" -Message "Insufficient CPU cores. Available: $totalCores - Required: $requiredCores" -Manager $Manager
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "CPU Cores" -Status "PASS" -Message "Sufficient CPU cores available. Available: $totalCores - meets requirement of $requiredCores" -Manager $Manager
    }
    
    # Test processor speed
    $averageProcessorSpeed = $SystemInfo.Hardware.AverageProcessorSpeedGHz
    $requiredProcessorSpeed = $config.MinimumRequirements.MinimumProcessorSpeedGHz
    
    if ($averageProcessorSpeed -lt $requiredProcessorSpeed) {
        Add-HealthCheckResult -Category "System Requirements" -Check "Processor Speed" -Status "FAIL" -Message "Insufficient processor speed. Available: $averageProcessorSpeed GHz - Required: $requiredProcessorSpeed GHz" -Manager $Manager
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "Processor Speed" -Status "PASS" -Message "Sufficient processor speed available. Available: $averageProcessorSpeed GHz - meets requirement of $requiredProcessorSpeed GHz" -Manager $Manager
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
            Add-HealthCheckResult -Category "System Requirements" -Check "IIS Installation" -Status "PASS" -Message "IIS is installed (Version: $iisVersion) - meets minimum requirement of $requiredIISVersion" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "System Requirements" -Check "IIS Installation" -Status "FAIL" -Message "IIS version $iisVersion is below minimum requirement of $requiredIISVersion" -Manager $Manager
        }
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check "IIS Installation" -Status "FAIL" -Message "IIS is not installed. Required for ESS deployment." -Manager $Manager
    }
    
    # Test .NET Framework version
    $dotNetVersions = $SystemInfo.Registry.DotNetVersions
    $requiredDotNetVersion = $config.MinimumRequirements.RequiredDotNetVersion
    
    if ($dotNetVersions -and $dotNetVersions.Count -gt 0) {
        $highestDotNetVersion = $dotNetVersions | Sort-Object -Descending | Select-Object -First 1
        
        # Parse version numbers for comparison
        $dotNetVersionParts = $highestDotNetVersion.Split('.')
        $requiredDotNetParts = $requiredDotNetVersion.Split('.')
        
        $dotNetVersionNum = [double]"$($dotNetVersionParts[0]).$($dotNetVersionParts[1])"
        $requiredDotNetNum = [double]"$($requiredDotNetParts[0]).$($requiredDotNetParts[1])"
        
        if ($dotNetVersionNum -ge $requiredDotNetNum) {
            Add-HealthCheckResult -Category "System Requirements" -Check ".NET Framework" -Status "PASS" -Message ".NET Framework $highestDotNetVersion installed - meets minimum requirement of $requiredDotNetVersion" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "System Requirements" -Check ".NET Framework" -Status "FAIL" -Message ".NET Framework $highestDotNetVersion is below minimum requirement of $requiredDotNetVersion" -Manager $Manager
        }
    } else {
        Add-HealthCheckResult -Category "System Requirements" -Check ".NET Framework" -Status "FAIL" -Message ".NET Framework is not installed. Required version: $requiredDotNetVersion" -Manager $Manager
    }
    
    # Test OS version and type
    $osCaption = $SystemInfo.OS.Caption
    $isServer = $SystemInfo.OS.IsServer
    $requiredOSVersions = $config.MinimumRequirements.RequiredOSVersions
    
    if ($isServer) {
        # Check if server OS meets minimum requirements
        $osSupported = $false
        $serverVersion = $null
        
        foreach ($requiredOS in $requiredOSVersions) {
            if ($osCaption -like "*$requiredOS*") {
                $osSupported = $true
                $serverVersion = $requiredOS
                break
            }
        }
        
        if ($osSupported) {
            Add-HealthCheckResult -Category "System Requirements" -Check "Operating System" -Status "PASS" -Message "Server OS is supported: $osCaption (Detected: $serverVersion)" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "System Requirements" -Check "Operating System" -Status "FAIL" -Message "Server OS is too old: $osCaption. Minimum required: $($requiredOSVersions -join ', ')" -Manager $Manager
        }
    } else {
        # Client OS - show as INFO since ESS is designed for server deployment
        Add-HealthCheckResult -Category "System Requirements" -Check "Operating System" -Status "INFO" -Message "Client OS detected: $osCaption. ESS is designed for server deployment, but ESS can still run on client systems." -Manager $Manager
    }
} 