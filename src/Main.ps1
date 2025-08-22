<#
.SYNOPSIS
    ESS Pre-Upgrade Health Checker - Main Entry Point
.DESCRIPTION
    Main entry point for the ESS Health Checker application
    Following call stack principles with proper module loading and dependency management
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

# Import the module loader first
. .\Core\ModuleLoader.ps1

function Initialize-ESSHealthChecker {
    <#
    .SYNOPSIS
        Initializes the ESS Health Checker application
    .DESCRIPTION
        Sets up the application environment and loads all required modules
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Initializing ESS Health Checker..." -ForegroundColor Yellow
        
        # Initialize module loader
        Initialize-ModuleLoader
        
        # Load all modules in the correct order
        Load-Modules
        
        # Test dependencies (temporarily disabled for debugging)
        # Test-HealthCheckDependencies
        
        Write-Host "ESS Health Checker initialized successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to initialize ESS Health Checker: $_"
        throw
    }
}

function Start-ESSHealthChecks {
    <#
    .SYNOPSIS
        Starts the ESS Health Check process using proper call stack principles
    .DESCRIPTION
        Uses the HealthCheckOrchestrator class to manage the entire health check workflow
        following proper dependency injection and call stack principles
    .RETURNS
        Path to the generated report
    #>
    [CmdletBinding()]
    param()

    try {
        Write-Host "Starting ESS Pre-Upgrade Health Checks..." -ForegroundColor Cyan
        
        # Load required modules in dependency order to ensure classes are available
        . .\Core\HealthCheckCore.ps1
        . .\Core\Config.ps1
        . .\modules\Utils\HelperFunctions.ps1
        . .\modules\System\HardwareInfo.ps1
        . .\modules\System\OSInfo.ps1
        . .\modules\System\IISInfo.ps1
        . .\modules\System\SQLInfo.ps1
        . .\modules\System\SystemInfoOrchestrator.ps1
        . .\modules\Detection\ESSDetection.ps1
        . .\modules\Detection\WFEDetection.ps1
        . .\modules\Detection\ESSHealthCheckAPI.ps1
        . .\modules\Detection\DetectionOrchestrator.ps1
        . .\modules\Validation\SystemRequirements.ps1
        . .\modules\Validation\InfrastructureValidation.ps1
        . .\modules\Validation\ESSValidation.ps1
        . .\modules\Validation\ValidationOrchestrator.ps1
        . .\Core\ReportGenerator.ps1
        
        # Import the main orchestrator after all dependent modules are loaded
        . .\Core\HealthCheckOrchestrator.ps1
        
        # Use the orchestrator pattern instead of individual function calls
        $orchestrator = [HealthCheckOrchestrator]::new()
        $orchestrator.Initialize()
        
        # Execute the complete health check workflow
        $orchestrator.CollectSystemInformation()
        $orchestrator.DetectESSWFEDeployment()
        $orchestrator.RunValidationChecks()
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

# Initialize the application when the script is loaded
Initialize-ESSHealthChecker

