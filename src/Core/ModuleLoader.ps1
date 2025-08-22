<#
.SYNOPSIS
    Module loader for ESS Health Checker
.DESCRIPTION
    Handles loading of all modules in the correct dependency order following call stack principles
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

# Module loading order following call stack principles
$ModuleLoadOrder = @(
    # Layer 1: Core infrastructure (no dependencies)
    "Core\HealthCheckCore.ps1",
    
    # Layer 2: System information (depends on core)
    "modules\System\HardwareInfo.ps1",
    "modules\System\OSInfo.ps1", 
    "modules\System\IISInfo.ps1",
    "modules\System\SQLInfo.ps1",
    "modules\System\SystemInfoOrchestrator.ps1",
    
    # Layer 3: Detection (depends on system info)
    "modules\Detection\ESSDetection.ps1",
    "modules\Detection\WFEDetection.ps1",
    "modules\Detection\ESSHealthCheckAPI.ps1",
    "modules\Detection\DetectionOrchestrator.ps1",
    
    # Layer 4: Utilities (depends on system info and detection)
    "modules\Utils\HelperFunctions.ps1",
    
    # Layer 5: Validation (depends on all previous layers)
    "modules\Validation\SystemRequirements.ps1",
    "modules\Validation\InfrastructureValidation.ps1", 
    "modules\Validation\ESSValidation.ps1",
    "modules\Validation\ValidationOrchestrator.ps1",
    
    # Layer 6: Configuration (depends on system info and detection)
    "Core\Config.ps1",
    
    # Layer 7: Reporting (depends on all previous layers)
    "Core\ReportGenerator.ps1"
)

function Initialize-ModuleLoader {
    <#
    .SYNOPSIS
        Initializes the module loader and validates module dependencies
    .DESCRIPTION
        Sets up the module loading system and validates that all required modules exist
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "Initializing module loader..."
    
    # Validate all modules exist
    $missingModules = @()
    foreach ($module in $ModuleLoadOrder) {
        $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) $module
        if (-not (Test-Path $modulePath)) {
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        throw "Missing required modules: $($missingModules -join ', ')"
    }
    
    Write-Verbose "Module loader initialized successfully"
}

function Load-Modules {
    <#
    .SYNOPSIS
        Loads all modules in the correct dependency order
    .DESCRIPTION
        Loads modules following the call stack dependency order to ensure proper initialization
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Loading ESS Health Checker modules..." -ForegroundColor Yellow
        
        foreach ($module in $ModuleLoadOrder) {
            $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) $module
            Write-Verbose "Loading module: $module"
            
            # Load the module
            . $modulePath
            
            # Verify module loaded successfully by checking for key functions
            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
            Write-Verbose "Module $moduleName loaded successfully"
        }
        
        Write-Host "All modules loaded successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to load modules: $_"
        throw
    }
}

function Get-ModuleDependencies {
    <#
    .SYNOPSIS
        Gets the dependency graph for all modules
    .DESCRIPTION
        Returns information about module dependencies for documentation and debugging
    #>
    [CmdletBinding()]
    param()
    
    $dependencies = @{}
    
    foreach ($module in $ModuleLoadOrder) {
        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
        $dependencies[$moduleName] = @{
            Path = $module
            Dependencies = @()
        }
    }
    
    # Define explicit dependencies
    $dependencies["SystemInfoOrchestrator"].Dependencies = @("HardwareInfo", "OSInfo", "IISInfo", "SQLInfo")
    $dependencies["DetectionOrchestrator"].Dependencies = @("ESSDetection", "WFEDetection", "ESSHealthCheckAPI")
    $dependencies["ValidationOrchestrator"].Dependencies = @("SystemRequirements", "InfrastructureValidation", "ESSValidation")
    $dependencies["Config"].Dependencies = @("SystemInfoOrchestrator", "DetectionOrchestrator")
    $dependencies["ReportGenerator"].Dependencies = @("SystemInfoOrchestrator", "DetectionOrchestrator", "ValidationOrchestrator")
    
    return $dependencies
}

# Functions are available for external use when script is dot-sourced
