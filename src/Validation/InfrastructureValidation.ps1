<#
.SYNOPSIS
    Infrastructure validation module
.DESCRIPTION
    Validates infrastructure components including IIS, database connectivity, and network
    Following call stack principles with dependency injection
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

function Test-IISConfiguration {
    <#
    .SYNOPSIS
        Tests IIS configuration
    .DESCRIPTION
        Validates IIS configuration using injected system information
    .PARAMETER SystemInfo
        System information object containing IIS details
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )

    Write-Verbose "Testing IIS configuration..."
    
    # IIS installation is already checked in System Requirements
    # Only proceed with configuration checks if IIS is installed
    if ($SystemInfo.IIS.IsInstalled) {
        # Test IIS sites
        if ($SystemInfo.IIS.Sites -and $SystemInfo.IIS.Sites.Count -gt 0) {
            Add-HealthCheckResult -Category "IIS Configuration" -Check "IIS Sites" -Status "PASS" -Message "Found $($SystemInfo.IIS.Sites.Count) IIS sites" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "IIS Configuration" -Check "IIS Sites" -Status "WARNING" -Message "No IIS sites found" -Manager $Manager
        }
        
        # Test IIS application pools
        if ($SystemInfo.IIS.ApplicationPools -and $SystemInfo.IIS.ApplicationPools.Count -gt 0) {
            Add-HealthCheckResult -Category "IIS Configuration" -Check "IIS Application Pools" -Status "PASS" -Message "Found $($SystemInfo.IIS.ApplicationPools.Count) IIS application pools" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "IIS Configuration" -Check "IIS Application Pools" -Status "WARNING" -Message "No IIS application pools found" -Manager $Manager
        }
    }
}

function Test-DatabaseInstanceConnectivity {
    <#
    .SYNOPSIS
        Tests database connectivity for a specific ESS or WFE instance
    .DESCRIPTION
        Validates database connectivity for a single ESS or WFE instance
        Following call stack principles with dependency injection
        Specific to ESS/WFE instances with their expected structure
    .PARAMETER Instance
        The ESS or WFE instance to test
    .PARAMETER InstanceType
        Type of instance ("ESS" or "WFE") for reporting purposes
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Instance,
        
        [Parameter(Mandatory = $true)]
        [string]$InstanceType,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )

    if (-not $Instance.DatabaseServer) {
        return
    }

    try {
        $connectionString = "Server=$($Instance.DatabaseServer);Database=$($Instance.DatabaseName);Integrated Security=true;Connection Timeout=30"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        $connection.Close()
        
        $message = "Successfully connected to PG database: $($Instance.DatabaseServer) - $($Instance.DatabaseName)"
        Add-HealthCheckResult -Category "Database Connectivity" -Check "$InstanceType - PG Database Connection" -Status "PASS" -Message $message -Manager $Manager
    }
    catch {
        $message = "Failed to connect to PG database: $($Instance.DatabaseServer) - $($Instance.DatabaseName). Error: $($_.Exception.Message)"
        Add-HealthCheckResult -Category "Database Connectivity" -Check "$InstanceType - PG Database Connection" -Status "FAIL" -Message $message -Manager $Manager
    }
}

function Test-DatabaseConnectivity {
    <#
    .SYNOPSIS
        Tests database connectivity
    .DESCRIPTION
        Validates database connectivity using injected detection results
        Refactored to use reusable helper function following DRY principles
    .PARAMETER DetectionResults
        Detection results containing ESS and WFE instances
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )

    Write-Verbose "Testing database connectivity..."
    
    # Test ESS database connectivity for all instances
    if ($DetectionResults -and $DetectionResults.ESSInstances.Count -gt 0) {
        foreach ($essInstance in $DetectionResults.ESSInstances) {
            Test-DatabaseInstanceConnectivity -Instance $essInstance -InstanceType "ESS" -Manager $Manager
        }
    }
    
    # Test WFE database connectivity for all instances
    if ($DetectionResults -and $DetectionResults.WFEInstances.Count -gt 0) {
        foreach ($wfeInstance in $DetectionResults.WFEInstances) {
            Test-DatabaseInstanceConnectivity -Instance $wfeInstance -InstanceType "WFE" -Manager $Manager
        }
    }
}

function Test-NetworkConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity
    .DESCRIPTION
        Validates network connectivity using injected system information
    .PARAMETER SystemInfo
        System information object containing network details
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )

    Write-Verbose "Testing network connectivity..."
    
    # Test basic network connectivity
    try {
        $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
        if ($pingResult) {
            Add-HealthCheckResult -Category "Network Connectivity" -Check "Internet Connectivity" -Status "PASS" -Message "Internet connectivity confirmed" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "Network Connectivity" -Check "Internet Connectivity" -Status "FAIL" -Message "No internet connectivity detected" -Manager $Manager
        }
    }
    catch {
        Add-HealthCheckResult -Category "Network Connectivity" -Check "Internet Connectivity" -Status "WARNING" -Message "Could not test internet connectivity" -Manager $Manager
    }
    
    # Test network adapters
    if ($SystemInfo.Network.NetworkAdapters -and $SystemInfo.Network.NetworkAdapters.Count -gt 0) {
        $activeAdapters = $SystemInfo.Network.NetworkAdapters | Where-Object { $_.Status -eq 'Up' }
        if ($activeAdapters.Count -gt 0) {
            Add-HealthCheckResult -Category "Network Connectivity" -Check "Network Adapters" -Status "PASS" -Message "Found $($activeAdapters.Count) active network adapters" -Manager $Manager
        } else {
            Add-HealthCheckResult -Category "Network Connectivity" -Check "Network Adapters" -Status "FAIL" -Message "No active network adapters found" -Manager $Manager
        }
    } else {
        Add-HealthCheckResult -Category "Network Connectivity" -Check "Network Adapters" -Status "WARNING" -Message "Could not retrieve network adapter information" -Manager $Manager
    }
}

function Test-SecurityPermissions {
    <#
    .SYNOPSIS
        Tests security permissions
    .DESCRIPTION
        Validates security permissions using injected system information
    .PARAMETER SystemInfo
        System information object containing security details
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )

    Write-Verbose "Testing security permissions..."
    
    # Test if running as administrator
    if ($SystemInfo.IsElevated) {
        Add-HealthCheckResult -Category "Security Permissions" -Check "Administrator Rights" -Status "PASS" -Message "Tool is running with administrator privileges" -Manager $Manager
    } else {
        Add-HealthCheckResult -Category "Security Permissions" -Check "Administrator Rights" -Status "WARNING" -Message "Tool is not running with administrator privileges. Some checks may fail." -Manager $Manager
    }
    
    # Test file system permissions
    $testPath = $env:TEMP
    try {
        $testFile = Join-Path $testPath "ESSHealthCheckTest.tmp"
        "Test" | Out-File -FilePath $testFile -ErrorAction Stop
        Remove-Item $testFile -ErrorAction SilentlyContinue
        Add-HealthCheckResult -Category "Security Permissions" -Check "File System Access" -Status "PASS" -Message "File system access confirmed" -Manager $Manager
    }
    catch {
        Add-HealthCheckResult -Category "Security Permissions" -Check "File System Access" -Status "FAIL" -Message "File system access denied" -Manager $Manager
    }
} 
