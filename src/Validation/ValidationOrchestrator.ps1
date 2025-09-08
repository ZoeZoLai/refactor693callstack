<#
.SYNOPSIS
    Validation orchestrator module
.DESCRIPTION
    Coordinates all validation checks including system requirements, infrastructure, and ESS-specific validations
    Following call stack principles with dependency injection
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

# Note: No imports needed - manager instances are passed as parameters
# This follows pure dependency injection principles

# Note: Using [object] type for Manager parameter to avoid linter errors
# The actual type is HealthCheckResultManager, but PowerShell linter can't resolve it

class ValidationManager {
    [hashtable]$SystemInfo
    [hashtable]$DetectionResults
    [hashtable]$Configuration
    [array]$ValidationResults
    
    ValidationManager() {
        $this.SystemInfo = @{}
        $this.DetectionResults = @{}
        $this.Configuration = @{}
        $this.ValidationResults = @()
    }
    
    [array]RunSystemValidation([hashtable]$SystemInfo, [hashtable]$DetectionResults, [object]$Manager, [hashtable]$Configuration = $null) {
        Write-Host "Starting system validation checks..." -ForegroundColor Yellow
        
        try {
            $this.SystemInfo = $SystemInfo
            $this.DetectionResults = $DetectionResults
            $this.Configuration = $Configuration
            $this.ValidationResults = @()
            
            # Run all validation checks with injected dependencies
            if ($SystemInfo -and $SystemInfo.Count -gt 0) {
                Test-SystemRequirements -SystemInfo $SystemInfo -Configuration $Configuration -Manager $Manager
                Test-IISConfiguration -SystemInfo $SystemInfo -Manager $Manager
                Test-NetworkConnectivity -SystemInfo $SystemInfo -Manager $Manager
                Test-SecurityPermissions -SystemInfo $SystemInfo -Manager $Manager
            } else {
                Write-Warning "System information is not available, skipping system-dependent validation checks"
                Add-HealthCheckResult -Category "Validation" -Check "System Information" -Status "WARNING" -Message "System information not available for validation" -Manager $Manager
            }
            
            Test-ESSWFEDetection -DetectionResults $DetectionResults -Manager $Manager
            Test-DatabaseConnectivity -DetectionResults $DetectionResults -Manager $Manager
            Test-WebConfigEncryptionValidation -DetectionResults $DetectionResults -Manager $Manager
            Test-ESSVersionValidation -DetectionResults $DetectionResults -Configuration $Configuration -Manager $Manager
            Test-ESSHTTPSValidation -DetectionResults $DetectionResults -Manager $Manager
            
            # Run ESS API health check validation
            Test-ESSAPIHealthCheckValidation -DetectionResults $DetectionResults -Configuration $Configuration -Manager $Manager
            
            # Get summary statistics
            $summary = Get-HealthCheckSummary -Manager $Manager
            $totalChecks = $summary.Total
            $passChecks = $summary.Pass
            $failChecks = $summary.Fail
            $warningChecks = $summary.Warning
            $infoChecks = $summary.Info
            
            # Ensure all counts are properly initialized
            $totalChecks = if ($totalChecks) { $totalChecks } else { 0 }
            $passChecks = if ($passChecks) { $passChecks } else { 0 }
            $failChecks = if ($failChecks) { $failChecks } else { 0 }
            $warningChecks = if ($warningChecks) { $warningChecks } else { 0 }
            $infoChecks = if ($infoChecks) { $infoChecks } else { 0 }
            
            Write-Host "`nSystem validation completed." -ForegroundColor Green
            Write-Host "Summary: $passChecks/$totalChecks passed, $failChecks failed, $warningChecks warnings, $infoChecks info items" -ForegroundColor Cyan
            
            $this.ValidationResults = Get-HealthCheckResults -Manager $Manager
            return $this.ValidationResults
        }
        catch {
            Write-Error "Error during system validation: $_"
            throw
        }
    }
}

# ValidationManager class is now instantiated and passed through the call stack
# No global variables needed - following call stack principles

function Start-SystemValidation {
    <#
    .SYNOPSIS
        Performs comprehensive system validation checks
    .DESCRIPTION
        Runs all validation checks with injected dependencies following call stack principles
    .PARAMETER SystemInfo
        System information object for validation
    .PARAMETER DetectionResults
        Detection results for ESS/WFE validation
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    .PARAMETER ValidationManager
        ValidationManager instance for validation operations
    .PARAMETER Configuration
        Optional configuration object for validation settings
    .RETURNS
        Array of validation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager,
        
        [Parameter(Mandatory = $true)]
        [object]$ValidationManager,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = $null
    )

    return $ValidationManager.RunSystemValidation($SystemInfo, $DetectionResults, $Manager, $Configuration)
}

function Test-ESSAPIHealthCheckValidation {
    <#
    .SYNOPSIS
        Validates ESS components using the health check API
    .DESCRIPTION
        Uses the dedicated ESSHealthCheckAPI module to perform API health checks
        with injected dependencies
    .PARAMETER DetectionResults
        Detection results containing ESS instances
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    .PARAMETER Configuration
        Optional configuration object for API settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = $null
    )

    try {
        Write-Verbose "Testing ESS API health check validation..."
        
        # Import the API health check functions
        $apiModulePath = Join-Path $PSScriptRoot "..\Detection\ESSHealthCheckAPI.ps1"
        if (Test-Path $apiModulePath) {
            . $apiModulePath
        } else {
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "Module Loading" -Status "FAIL" -Message "ESSHealthCheckAPI.ps1 module not found at: $apiModulePath" -Manager $Manager
            return
        }
        
        if (-not $DetectionResults -or -not $DetectionResults.ESSInstances) {
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "ESS Detection" -Status "WARNING" -Message "No ESS instances detected for API health check validation" -Manager $Manager
            return
        }
        
        # Get health check for all instances and add results
        try {
            # Get timeout settings from configuration
            $timeoutSeconds = if ($Configuration -and $Configuration.APIHealthCheck -and $Configuration.APIHealthCheck.DefaultTimeoutSeconds) { 
                $Configuration.APIHealthCheck.DefaultTimeoutSeconds 
            } else { 
                90 
            }
            $maxRetries = if ($Configuration -and $Configuration.APIHealthCheck -and $Configuration.APIHealthCheck.MaxRetries) { 
                $Configuration.APIHealthCheck.MaxRetries 
            } else { 
                2 
            }
            $retryDelay = if ($Configuration -and $Configuration.APIHealthCheck -and $Configuration.APIHealthCheck.RetryDelaySeconds) { 
                $Configuration.APIHealthCheck.RetryDelaySeconds 
            } else { 
                5 
            }
            
            Write-Verbose "Using API health check settings: Timeout=$timeoutSeconds seconds, MaxRetries=$maxRetries, RetryDelay=$retryDelay seconds"
            
            $healthChecks = Get-ESSHealthCheckForAllInstances -DetectionResults $DetectionResults -TimeoutSeconds $timeoutSeconds -MaxRetries $maxRetries -RetryDelaySeconds $retryDelay
            
            # Handle PowerShell's behavior where single objects aren't arrays
            if ($healthChecks -is [array]) {
                $healthCheckCount = $healthChecks.Count
            } else {
                $healthCheckCount = if ($null -ne $healthChecks) { 1 } else { 0 }
            }
            
            if ($healthCheckCount -gt 0) {
                # Add API health check results to global results
                Add-APIHealthCheckResults -HealthChecks $healthChecks -Manager $Manager
                Write-Verbose "Successfully added $healthCheckCount ESS API health check results"
            } else {
                Add-HealthCheckResult -Category "ESS API Health Check" -Check "API Health Check" -Status "WARNING" -Message "No health check results returned from API" -Manager $Manager
            }
        }
        catch {
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "API Health Check" -Status "FAIL" -Message "Error during API health check validation: $($_.Exception.Message)" -Manager $Manager
        }
    }
    catch {
        Write-Error "Error during ESS API health check validation: $_"
        Add-HealthCheckResult -Category "ESS API Health Check" -Check "Validation Process" -Status "FAIL" -Message "Error during validation process: $($_.Exception.Message)" -Manager $Manager
    }
}

