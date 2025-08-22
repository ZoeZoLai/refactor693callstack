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
    
    [array]RunSystemValidation([hashtable]$SystemInfo, [hashtable]$DetectionResults, [hashtable]$Configuration = $null) {
        Write-Host "Starting system validation checks..." -ForegroundColor Yellow
        
        try {
            $this.SystemInfo = $SystemInfo
            $this.DetectionResults = $DetectionResults
            $this.Configuration = $Configuration
            $this.ValidationResults = @()
            
            # Run all validation checks with injected dependencies
            if ($SystemInfo -and $SystemInfo.Count -gt 0) {
                Test-SystemRequirements -SystemInfo $SystemInfo -Configuration $Configuration
                Test-IISConfiguration -SystemInfo $SystemInfo
                Test-NetworkConnectivity -SystemInfo $SystemInfo
                Test-SecurityPermissions -SystemInfo $SystemInfo
            } else {
                Write-Warning "System information is not available, skipping system-dependent validation checks"
                Add-HealthCheckResult -Category "Validation" -Check "System Information" -Status "WARNING" -Message "System information not available for validation"
            }
            
            Test-ESSWFEDetection -DetectionResults $DetectionResults
            Test-DatabaseConnectivity -DetectionResults $DetectionResults
            Test-WebConfigEncryptionValidation -DetectionResults $DetectionResults
            Test-ESSVersionValidation -DetectionResults $DetectionResults -Configuration $Configuration
            Test-ESSHTTPSValidation -DetectionResults $DetectionResults
            
            # Run ESS API health check validation
            Test-ESSAPIHealthCheckValidation -DetectionResults $DetectionResults -Configuration $Configuration
            
            # Get summary statistics
            $summary = Get-HealthCheckSummary
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
            
            $this.ValidationResults = Get-HealthCheckResults
            return $this.ValidationResults
        }
        catch {
            Write-Error "Error during system validation: $_"
            throw
        }
    }
}

# Global validation manager instance
$script:ValidationManager = $null

function Get-ValidationManager {
    <#
    .SYNOPSIS
        Gets the validation manager instance
    .DESCRIPTION
        Returns the singleton validation manager instance
    #>
    [CmdletBinding()]
    param()
    
    if ($null -eq $script:ValidationManager) {
        $script:ValidationManager = [ValidationManager]::new()
    }
    
    return $script:ValidationManager
}

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
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = $null
    )

    $manager = Get-ValidationManager
    return $manager.RunSystemValidation($SystemInfo, $DetectionResults, $Configuration)
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
    .PARAMETER Configuration
        Optional configuration object for API settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults,
        
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
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "Module Loading" -Status "FAIL" -Message "ESSHealthCheckAPI.ps1 module not found at: $apiModulePath"
            return
        }
        
        if (-not $DetectionResults -or -not $DetectionResults.ESSInstances) {
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "ESS Detection" -Status "WARNING" -Message "No ESS instances detected for API health check validation"
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
                Add-APIHealthCheckResults -HealthChecks $healthChecks
                Write-Verbose "Successfully added $healthCheckCount ESS API health check results"
            } else {
                Add-HealthCheckResult -Category "ESS API Health Check" -Check "API Health Check" -Status "WARNING" -Message "No health check results returned from API"
            }
        }
        catch {
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "API Health Check" -Status "FAIL" -Message "Error during API health check validation: $($_.Exception.Message)"
        }
    }
    catch {
        Write-Error "Error during ESS API health check validation: $_"
        Add-HealthCheckResult -Category "ESS API Health Check" -Check "Validation Process" -Status "FAIL" -Message "Error during validation process: $($_.Exception.Message)"
    }
}

# Initialize the validation manager when the module is loaded
$script:ValidationManager = [ValidationManager]::new() 