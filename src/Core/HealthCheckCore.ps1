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
        HealthCheckResultManager instance (required)
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
        
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )
    
    $Manager.AddResult($Category, $Check, $Status, $Message)
}

function Get-HealthCheckResults {
    <#
    .SYNOPSIS
        Gets all health check results using dependency injection
    .DESCRIPTION
        Returns all health check results from the manager
    .PARAMETER Manager
        HealthCheckResultManager instance (required)
    .RETURNS
        Array of health check results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )
    
    return $Manager.GetResults()
}


function Get-HealthCheckSummary {
    <#
    .SYNOPSIS
        Gets a summary of health check results using dependency injection
    .DESCRIPTION
        Returns statistics about the health check results
    .PARAMETER Manager
        HealthCheckResultManager instance (required)
    .RETURNS
        Object containing summary statistics
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )
    
    return $Manager.GetSummary()
}

