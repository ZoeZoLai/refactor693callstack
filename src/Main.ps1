<#
.SYNOPSIS
    ESS Pre-Upgrade Health Checker - Main Entry Point
.DESCRIPTION
    Main entry point for the ESS Health Checker application
    Simplified structure with direct module loading
.NOTES
    Author: Zoe Lai
    Date: 23/08/2025
    Version: 2.0 - Simplified Structure
#>

# Load all required modules in logical order
Write-Host "Loading ESS Health Checker modules..." -ForegroundColor Yellow

# Core modules first (dependencies for other modules)
. .\Core\HealthCheckCore.ps1
. .\Core\Config.ps1

# Utility modules
. .\Utils\HelperFunctions.ps1

# System modules (depends on Core modules)
. .\System\OSInfo.ps1
. .\System\HardwareInfo.ps1
. .\System\IISInfo.ps1
. .\System\SQLInfo.ps1
. .\System\SystemInfoOrchestrator.ps1
. .\System\SystemRequirements.ps1
. .\System\InfrastructureValidation.ps1
. .\System\ESSValidation.ps1
. .\System\ValidationOrchestrator.ps1
. .\System\SystemValidation.ps1

# Detection modules (depends on System modules)
. .\Detection\ESSDetection.ps1
. .\Detection\WFEDetection.ps1
. .\Detection\DetectionOrchestrator.ps1

# Report generation (depends on all other modules)
. .\Core\ReportGenerator.ps1

Write-Host "All modules loaded successfully!" -ForegroundColor Green

function Start-ESSHealthChecks {
    <#
    .SYNOPSIS
        Starts the ESS Health Check process
    .DESCRIPTION
        Runs the complete health check workflow with simplified structure
    .RETURNS
        Path to the generated report
    #>
    [CmdletBinding()]
    param()

    try {
        Write-Host "Starting ESS Pre-Upgrade Health Checks..." -ForegroundColor Cyan
        
        # Step 1: Collect system information
        Write-Host "Step 1: Collecting system information..." -ForegroundColor Yellow
        $systemInfo = Get-SystemInformation
        
        # Step 2: Detect ESS/WFE installations
        Write-Host "Step 2: Detecting ESS/WFE installations..." -ForegroundColor Yellow
        $detectionResults = Get-ESSWFEDetection -SystemInfo $systemInfo
        
        # Step 3: Run validation checks
        Write-Host "Step 3: Running validation checks..." -ForegroundColor Yellow
        Start-SystemValidation -SystemInfo $systemInfo -DetectionResults $detectionResults
        
        # Step 4: Generate report
        Write-Host "Step 4: Generating health check report..." -ForegroundColor Yellow
        $results = Get-HealthCheckResults
        $reportPath = New-HealthCheckReport -Results $results -SystemInfo $systemInfo -DetectionResults $detectionResults
        
        # Step 5: Display summary
        Write-Host "`n=== Health Check Summary ===" -ForegroundColor Magenta
        Write-Host "System Information:" -ForegroundColor White
        Write-Host "  Computer Name: $($systemInfo.ComputerName)" -ForegroundColor White
        Write-Host "  OS Version: $($systemInfo.OS.Caption)" -ForegroundColor White
        Write-Host "  IIS Installed: $($systemInfo.IIS.IsInstalled)" -ForegroundColor White
        
        Write-Host "Detection Results:" -ForegroundColor White
        Write-Host "  ESS Instances: $($detectionResults.ESSInstances.Count)" -ForegroundColor White
        Write-Host "  WFE Instances: $($detectionResults.WFEInstances.Count)" -ForegroundColor White
        Write-Host "  Deployment Type: $($detectionResults.DeploymentType)" -ForegroundColor White
        
        $summary = Get-HealthCheckSummary
        Write-Host "Health Check Results:" -ForegroundColor White
        Write-Host "  Total Checks: $($summary.Total)" -ForegroundColor White
        Write-Host "  Passed: $($summary.Pass)" -ForegroundColor Green
        Write-Host "  Failed: $($summary.Fail)" -ForegroundColor Red
        Write-Host "  Warnings: $($summary.Warning)" -ForegroundColor Yellow
        Write-Host "  Info: $($summary.Info)" -ForegroundColor Cyan
        Write-Host "=============================" -ForegroundColor Magenta
        
        Write-Host "`nHealth Checks completed successfully!" -ForegroundColor Green
        Write-Host "Report generated at: $reportPath" -ForegroundColor Cyan
        return $reportPath
    } 
    catch {
        Write-Error "An error occurred during the ESS Health Check: $_"
        throw
    }
}

