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

class HealthCheckOrchestrator {
    [object]$Configuration
    [object]$HealthCheckManager
    [hashtable]$SystemInfo
    [hashtable]$DetectionResults
    
    HealthCheckOrchestrator() {
        $this.Configuration = $null
        $this.HealthCheckManager = $null
        $this.SystemInfo = @{}
        $this.DetectionResults = @{}
    }
    
    [void]Initialize() {
        Write-Verbose "Initializing Health Check Orchestrator..."
        
        # Clear any existing health check results
        Clear-HealthCheckResults
        
        # Initialize configuration
        $this.Configuration = Get-ESSConfiguration
        
        Write-Verbose "Health Check Orchestrator initialized successfully"
    }
    
    [void]CollectSystemInformation() {
        Write-Host "Step 1: Collecting system information..." -ForegroundColor Cyan
        
        try {
            # Use the SystemInformationManager class
            $systemManager = [SystemInformationManager]::new()
            $this.SystemInfo = $systemManager.CollectSystemInformation()
            
            Write-Host "System information collected successfully" -ForegroundColor Green
            Write-Host "SystemInfo contains $($this.SystemInfo.Count) items" -ForegroundColor Yellow
            Write-Host "SystemInfo keys: $($this.SystemInfo.Keys -join ', ')" -ForegroundColor Yellow
        }
        catch {
            Write-Error "Failed to collect system information: $_"
            throw
        }
    }
    
    [void]DetectESSWFEDeployment() {
        Write-Host "Step 2: Detecting ESS/WFE deployment..." -ForegroundColor Cyan
        
        try {
            # Use the DetectionManager class
            $detectionManager = [DetectionManager]::new()
            $this.DetectionResults = $detectionManager.DetectESSWFEDeployment($this.SystemInfo)
            
            Write-Host "ESS/WFE deployment detection completed" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to detect ESS/WFE deployment: $_"
            throw
        }
    }
    
    [void]RunValidationChecks() {
        Write-Host "Step 3: Running validation checks..." -ForegroundColor Cyan
        
        try {
            # Use the ValidationManager class
            $validationManager = [ValidationManager]::new()
            
            # Pass null for Configuration since it's optional and we have type mismatch issues
            $validationManager.RunSystemValidation($this.SystemInfo, $this.DetectionResults, $null)
            
            Write-Host "Validation checks completed" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to run validation checks: $_"
            throw
        }
    }
    
    [string]GenerateReport() {
        Write-Host "Step 4: Generating health check report..." -ForegroundColor Cyan
        
        try {
            # Get health check results using the core functions
            $results = Get-HealthCheckResults
            
            # Generate report with injected dependencies
            # Pass null for Configuration since it's optional and we have type mismatch issues
            $reportPath = New-HealthCheckReport -Results $results
            
            Write-Host "Report generated successfully" -ForegroundColor Green
            return $reportPath
        }
        catch {
            Write-Error "Failed to generate report: $_"
            throw
        }
    }
    
    [void]DisplaySummary() {
        Write-Host "`n=== Health Check Summary ===" -ForegroundColor Magenta
        
        # Display system information summary
        Write-Host "System Information:" -ForegroundColor White
        Write-Host "  Computer Name: $($this.SystemInfo.ComputerName)" -ForegroundColor White
        Write-Host "  OS Version: $($this.SystemInfo.OSVersion)" -ForegroundColor White
        Write-Host "  IIS Installed: $($this.SystemInfo.IIS.IsInstalled)" -ForegroundColor White
        
        # Display detection results
        Write-Host "Detection Results:" -ForegroundColor White
        Write-Host "  ESS Instances: $($this.DetectionResults.ESSInstances.Count)" -ForegroundColor White
        Write-Host "  WFE Instances: $($this.DetectionResults.WFEInstances.Count)" -ForegroundColor White
        Write-Host "  Deployment Type: $($this.DetectionResults.DeploymentType)" -ForegroundColor White
        
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
}

function Start-ESSHealthChecks {
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
        
        # Create orchestrator instance
        $orchestrator = [HealthCheckOrchestrator]::new()
        
        # Initialize orchestrator
        $orchestrator.Initialize()
        
        # Execute health check workflow
        $orchestrator.CollectSystemInformation()
        $orchestrator.DetectESSWFEDeployment()
        $orchestrator.RunValidationChecks()
        
        # Generate report
        $reportPath = $orchestrator.GenerateReport()
        
        # Display summary
        $orchestrator.DisplaySummary()
        
        Write-Host "`nHealth Checks completed successfully!" -ForegroundColor Green
        Write-Host "Report generated at: $reportPath" -ForegroundColor Cyan
        
        return $reportPath
    } 
    catch {
        Write-Error "An error occurred during the ESS Health Check: $_"
        throw
    }
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
