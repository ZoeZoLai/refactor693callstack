<#
.SYNOPSIS
    Core health check utilities and result management
.DESCRIPTION
    Provides centralized functions for health check result management following call stack principles
.NOTES
    Author: Zoe Lai
    Date: 23/08/2025
    Version: 2.0 - Call Stack Principles
#>

# Health Check Result Manager Class
class HealthCheckResultManager {
    [System.Collections.ArrayList]$Results
    
    HealthCheckResultManager() {
        $this.Results = [System.Collections.ArrayList]::new()
    }
    
    [void]AddResult([string]$Category, [string]$Check, [string]$Status, [string]$Message) {
        $result = @{
            Category = $Category
            Check = $Check
            Status = $Status
            Message = $Message
            Timestamp = Get-Date
        }
        
        $this.Results.Add([PSCustomObject]$result) | Out-Null
        
        # Debug: Log when FAIL results are added
        if ($Status -eq "FAIL") {
            Write-Verbose "Added FAIL result: $Category - $Check (Total results now: $($this.Results.Count))"
        }
        
        # Display result with appropriate color
        $color = switch ($Status) {
            "PASS" { "Green" }
            "FAIL" { "Red" }
            "WARNING" { "Yellow" }
            "INFO" { "Cyan" }
            default { "White" }
        }
        
        Write-Host "[$Status] $Category - $Check : $Message" -ForegroundColor $color
    }
    
    [array]GetResults() {
        return $this.Results.ToArray()
    }
    
    [void]ClearResults() {
        $this.Results.Clear()
        Write-Verbose "Health check results cleared"
    }
    
    [hashtable]GetSummary() {
        $totalChecks = $this.Results.Count
        $passChecks = 0
        $failChecks = 0
        $warningChecks = 0
        $infoChecks = 0
        
        foreach ($result in $this.Results) {
            switch ($result.Status) {
                "PASS" { $passChecks++ }
                "FAIL" { $failChecks++ }
                "WARNING" { $warningChecks++ }
                "INFO" { $infoChecks++ }
            }
        }
        
        return @{
            Total = $totalChecks
            Pass = $passChecks
            Fail = $failChecks
            Warning = $warningChecks
            Info = $infoChecks
        }
    }
    
    [array]GetResultsByCategory([string]$Category) {
        return $this.Results | Where-Object { $_.Category -eq $Category }
    }
    
    [array]GetResultsByStatus([string]$Status) {
        return $this.Results | Where-Object { $_.Status -eq $Status }
    }
}

# Global result manager instance (singleton pattern for backward compatibility)
$script:HealthCheckManager = $null

function Get-HealthCheckManager {
    <#
    .SYNOPSIS
        Gets the global health check result manager instance
    .DESCRIPTION
        Returns the singleton HealthCheckResultManager instance
    .RETURNS
        HealthCheckResultManager instance
    #>
    [CmdletBinding()]
    param()
    
    if ($null -eq $script:HealthCheckManager) {
        $script:HealthCheckManager = [HealthCheckResultManager]::new()
    }
    
    return $script:HealthCheckManager
}

function Add-HealthCheckResult {
    <#
    .SYNOPSIS
        Adds a health check result using dependency injection
    .PARAMETER Category
        Category of the health check
    .PARAMETER Check
        Name of the check
    .PARAMETER Status
        Status of the check (PASS, FAIL, WARNING, INFO)
    .PARAMETER Message
        Detailed message about the check result
    .PARAMETER Manager
        Optional HealthCheckResultManager instance (for testing)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $true)]
        [string]$Check,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("PASS", "FAIL", "WARNING", "INFO")]
        [string]$Status,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [HealthCheckResultManager]$Manager = $null
    )
    
    if ($null -eq $Manager) {
        $Manager = Get-HealthCheckManager
    }
    
    $Manager.AddResult($Category, $Check, $Status, $Message)
}

function Get-HealthCheckResults {
    <#
    .SYNOPSIS
        Gets all health check results using dependency injection
    .DESCRIPTION
        Returns all health check results from the manager
    .PARAMETER Manager
        Optional HealthCheckResultManager instance (for testing)
    .RETURNS
        Array of health check results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [HealthCheckResultManager]$Manager = $null
    )
    
    if ($null -eq $Manager) {
        $Manager = Get-HealthCheckManager
    }
    
    return $Manager.GetResults()
}

function Clear-HealthCheckResults {
    <#
    .SYNOPSIS
        Clears all health check results using dependency injection
    .DESCRIPTION
        Resets the health check results in the manager
    .PARAMETER Manager
        Optional HealthCheckResultManager instance (for testing)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [HealthCheckResultManager]$Manager = $null
    )
    
    if ($null -eq $Manager) {
        $Manager = Get-HealthCheckManager
    }
    
    $Manager.ClearResults()
}

function Get-HealthCheckSummary {
    <#
    .SYNOPSIS
        Gets a summary of health check results using dependency injection
    .DESCRIPTION
        Returns statistics about the health check results
    .PARAMETER Manager
        Optional HealthCheckResultManager instance (for testing)
    .RETURNS
        Object containing summary statistics
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [HealthCheckResultManager]$Manager = $null
    )
    
    if ($null -eq $Manager) {
        $Manager = Get-HealthCheckManager
    }
    
    return $Manager.GetSummary()
}

function Get-HealthCheckResultsByCategory {
    <#
    .SYNOPSIS
        Gets health check results filtered by category using dependency injection
    .PARAMETER Category
        Category to filter by
    .PARAMETER Manager
        Optional HealthCheckResultManager instance (for testing)
    .RETURNS
        Array of health check results for the specified category
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [HealthCheckResultManager]$Manager = $null
    )
    
    if ($null -eq $Manager) {
        $Manager = Get-HealthCheckManager
    }
    
    return $Manager.GetResultsByCategory($Category)
}

function Get-HealthCheckResultsByStatus {
    <#
    .SYNOPSIS
        Gets health check results filtered by status using dependency injection
    .PARAMETER Status
        Status to filter by (PASS, FAIL, WARNING, INFO)
    .PARAMETER Manager
        Optional HealthCheckResultManager instance (for testing)
    .RETURNS
        Array of health check results for the specified status
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("PASS", "FAIL", "WARNING", "INFO")]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [HealthCheckResultManager]$Manager = $null
    )
    
    if ($null -eq $Manager) {
        $Manager = Get-HealthCheckManager
    }
    
    return $Manager.GetResultsByStatus($Status)
}