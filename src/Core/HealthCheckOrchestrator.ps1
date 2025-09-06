<#
.SYNOPSIS
    Main orchestrator for ESS Health Checker
.DESCRIPTION
    Coordinates the entire health check process following call stack principles
    Manages the execution flow and dependencies between different components
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

function Start-ESSHealthChecksOrchestrator {
    <#
    .SYNOPSIS
        Starts the ESS Health Check process
    .DESCRIPTION
        Initializes configuration and runs all health checks following call stack principles
    .RETURNS
        Path to the generated report
    #>
    [CmdletBinding()]
    param()

    try {
        Write-Host "Starting ESS Pre-Upgrade Health Checks..." -ForegroundColor Cyan
        
        # Initialize health check process
        Initialize-HealthCheckProcess
        
        # Execute health check workflow
        $systemInfo = Start-SystemInformationCollection
        $detectionResults = Get-ESSWFEDeployment -SystemInfo $systemInfo
        Start-ValidationChecks -SystemInfo $systemInfo -DetectionResults $detectionResults
        
        # Generate report
        $reportPath = Start-HealthCheckReportGeneration -SystemInfo $systemInfo -DetectionResults $detectionResults
        
        # Display summary
        Show-HealthCheckSummary -SystemInfo $systemInfo -DetectionResults $detectionResults
        
        Write-Host "`nHealth Checks completed successfully!" -ForegroundColor Green
        Write-Host "Report generated at: $reportPath" -ForegroundColor Cyan
        
        return $reportPath
    } 
    catch {
        Write-Error "An error occurred during the ESS Health Check: $_"
        throw
    }
}

function Initialize-HealthCheckProcess {
    <#
    .SYNOPSIS
        Initializes the health check process
    .DESCRIPTION
        Clears existing results and initializes configuration
    #>
    Write-Verbose "Initializing Health Check Process..."
    
    # Clear any existing health check results
    Clear-HealthCheckResults
    
    # Initialize configuration
    $null = Get-ESSConfiguration
    
    Write-Verbose "Health Check Process initialized successfully"
}

function Start-SystemInformationCollection {
    <#
    .SYNOPSIS
        Collects system information
    .DESCRIPTION
        Gathers comprehensive system information using direct function calls
    .RETURNS
        Hashtable containing system information
    #>
    Write-Host "Step 1: Collecting system information..." -ForegroundColor Cyan
    
    try {
        $systemInfo = Get-SystemInformation
        
        Write-Host "System information collected successfully" -ForegroundColor Green
        Write-Host "SystemInfo contains $($systemInfo.Count) items" -ForegroundColor Yellow
        Write-Host "SystemInfo keys: $($systemInfo.Keys -join ', ')" -ForegroundColor Yellow
        
        return $systemInfo
    }
    catch {
        Write-Error "Failed to collect system information: $_"
        throw
    }
}

function Get-ESSWFEDeployment {
    <#
    .SYNOPSIS
        Detects ESS/WFE deployment
    .DESCRIPTION
        Detects ESS and WFE installations using direct function calls
    .PARAMETER SystemInfo
        System information hashtable
    .RETURNS
        Hashtable containing detection results
    #>
    [CmdletBinding()]
    param(
        [hashtable]$SystemInfo
    )
    
    Write-Host "Step 2: Detecting ESS/WFE deployment..." -ForegroundColor Cyan
    
    try {
        $detectionResults = Get-ESSWFEDetection -SystemInfo $SystemInfo
        
        Write-Host "ESS/WFE deployment detection completed" -ForegroundColor Green
        
        return $detectionResults
    }
    catch {
        Write-Error "Failed to detect ESS/WFE deployment: $_"
        throw
    }
}

function Start-ValidationChecks {
    <#
    .SYNOPSIS
        Runs validation checks
    .DESCRIPTION
        Performs comprehensive system validation using direct function calls
    .PARAMETER SystemInfo
        System information hashtable
    .PARAMETER DetectionResults
        Detection results hashtable
    #>
    [CmdletBinding()]
    param(
        [hashtable]$SystemInfo,
        [hashtable]$DetectionResults
    )
    
    Write-Host "Step 3: Running validation checks..." -ForegroundColor Cyan
    
    try {
        Start-SystemValidation -SystemInfo $SystemInfo -DetectionResults $DetectionResults
        
        Write-Host "Validation checks completed" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to run validation checks: $_"
        throw
    }
}

function Start-HealthCheckReportGeneration {
    <#
    .SYNOPSIS
        Generates health check report
    .DESCRIPTION
        Creates HTML report using direct function calls
    .PARAMETER SystemInfo
        System information hashtable
    .PARAMETER DetectionResults
        Detection results hashtable
    .RETURNS
        Path to the generated report
    #>
    [CmdletBinding()]
    param(
        [hashtable]$SystemInfo,
        [hashtable]$DetectionResults
    )
    
    Write-Host "Step 4: Generating health check report..." -ForegroundColor Cyan
    
    try {
        # Get health check results using the core functions
        $results = Get-HealthCheckResults
        
        # Generate report with system info and detection results
        $reportPath = New-HealthCheckReport -Results $results -SystemInfo $SystemInfo -DetectionResults $DetectionResults
        
        Write-Host "Report generated successfully" -ForegroundColor Green
        return $reportPath
    }
    catch {
        Write-Error "Failed to generate report: $_"
        throw
    }
}

function Show-HealthCheckSummary {
    <#
    .SYNOPSIS
        Displays health check summary
    .DESCRIPTION
        Shows comprehensive summary of health check results
    .PARAMETER SystemInfo
        System information hashtable
    .PARAMETER DetectionResults
        Detection results hashtable
    #>
    [CmdletBinding()]
    param(
        [hashtable]$SystemInfo,
        [hashtable]$DetectionResults
    )
    
    Write-Host "`n=== Health Check Summary ===" -ForegroundColor Magenta
    
    # Display system information summary
    Write-Host "System Information:" -ForegroundColor White
    Write-Host "  Computer Name: $($SystemInfo.ComputerName)" -ForegroundColor White
    Write-Host "  OS Version: $($SystemInfo.OS.Caption)" -ForegroundColor White
    Write-Host "  IIS Installed: $($SystemInfo.IIS.IsInstalled)" -ForegroundColor White
    
    # Display detection results
    Write-Host "Detection Results:" -ForegroundColor White
    Write-Host "  ESS Instances: $($DetectionResults.ESSInstances.Count)" -ForegroundColor White
    Write-Host "  WFE Instances: $($DetectionResults.WFEInstances.Count)" -ForegroundColor White
    Write-Host "  Deployment Type: $($DetectionResults.DeploymentType)" -ForegroundColor White
    
    # Display health check summary using core functions
    $summary = Get-HealthCheckSummary
    Write-Host "Health Check Results:" -ForegroundColor White
    Write-Host "  Total Checks: $($summary.Total)" -ForegroundColor White
    Write-Host "  Passed: $($summary.Pass)" -ForegroundColor Green
    Write-Host "  Failed: $($summary.Fail)" -ForegroundColor Red
    Write-Host "  Warnings: $($summary.Warning)" -ForegroundColor Yellow
    Write-Host "  Info: $($summary.Info)" -ForegroundColor Cyan
    
    Write-Host "=============================" -ForegroundColor Magenta
}

function Test-HealthCheckDependencies {
    <#
    .SYNOPSIS
        Tests that all required dependencies are available
    .DESCRIPTION
        Validates that all required functions and modules are loaded
    #>
    [CmdletBinding()]
    param()
    
    $requiredFunctions = @(
        "Get-SystemInformation",
        "Get-ESSWFEDetection", 
        "Start-SystemValidation",
        "Get-HealthCheckResults",
        "New-HealthCheckReport",
        "Show-SystemInfoSummary",
        "Get-HealthCheckSummary",
        "Update-ESSConfiguration",
        "Update-SystemDeploymentInformation"
    )
    
    $missingFunctions = @()
    
    foreach ($function in $requiredFunctions) {
        if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
            $missingFunctions += $function
        }
    }
    
    if ($missingFunctions.Count -gt 0) {
        throw "Missing required functions: $($missingFunctions -join ', ')"
    }
    
    Write-Verbose "All required dependencies are available"
}
