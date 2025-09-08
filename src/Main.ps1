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

# System information modules (depends on Core modules)
. .\SystemInfo\OSInfo.ps1
. .\SystemInfo\HardwareInfo.ps1
. .\SystemInfo\IISInfo.ps1
. .\SystemInfo\SQLInfo.ps1
. .\SystemInfo\SystemInfoOrchestrator.ps1

# Validation modules (depends on SystemInfo modules)
. .\Validation\SystemRequirements.ps1
. .\Validation\InfrastructureValidation.ps1
. .\Validation\ESSValidation.ps1
. .\Validation\ValidationOrchestrator.ps1

# Detection modules (depends on SystemInfo modules)
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
        
        # Create all manager instances at the top level - no global variables needed
        # Use explicit object creation to avoid type resolution issues
        $healthCheckManager = New-Object -TypeName HealthCheckResultManager
        $detectionManager = New-Object -TypeName DetectionManager
        $validationManager = New-Object -TypeName ValidationManager
        $systemInfoManager = New-Object -TypeName SystemInformationManager
        
        # Step 1: Collect system information
        Write-Host "Step 1: Collecting system information..." -ForegroundColor Yellow
        $systemInfo = Get-SystemInformation -SystemInfoManager $systemInfoManager
        
        # Step 2: Detect ESS/WFE installations
        Write-Host "Step 2: Detecting ESS/WFE installations..." -ForegroundColor Yellow
        $detectionResults = Get-ESSWFEDetection -SystemInfo $systemInfo -Manager $healthCheckManager -DetectionManager $detectionManager
        
        # Step 3: Run validation checks
        Write-Host "Step 3: Running validation checks..." -ForegroundColor Yellow
        Start-SystemValidation -SystemInfo $systemInfo -DetectionResults $detectionResults -Manager $healthCheckManager -ValidationManager $validationManager
        
        # Step 4: Generate report
        Write-Host "Step 4: Generating health check report..." -ForegroundColor Yellow
        $results = Get-HealthCheckResults -Manager $healthCheckManager
        $reportPath = New-HealthCheckReport -Results $results -SystemInfo $systemInfo -DetectionResults $detectionResults -Manager $healthCheckManager
        
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
        
        $summary = Get-HealthCheckSummary -Manager $healthCheckManager
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

