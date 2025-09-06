<#
.SYNOPSIS
    System validation module using original working validation functions
.DESCRIPTION
    Uses the original working validation orchestrator for comprehensive validation
.NOTES
    Author: Zoe Lai
    Date: 23/08/2025
    Version: 2.0 - Using Original Working Code
#>

function Start-SystemValidation {
    <#
    .SYNOPSIS
        Performs comprehensive system validation checks
    .DESCRIPTION
        Uses the original working validation orchestrator for all validation checks
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

    Write-Host "Running system validation..." -ForegroundColor Yellow
    
    try {
        # Use the original working validation orchestrator
        . .\Validation\ValidationOrchestrator.ps1
        
        # Get the validation manager and run validation
        $manager = Get-ValidationManager
        $validationResults = $manager.RunSystemValidation($SystemInfo, $DetectionResults, $Configuration)
        
        Write-Host "System validation completed successfully" -ForegroundColor Green
        return $validationResults
    }
    catch {
        Write-Error "Error during system validation: $_"
        Add-HealthCheckResult -Category "Validation" -Check "Validation Process" -Status "FAIL" -Message "Error during validation: $($_.Exception.Message)"
    }
}