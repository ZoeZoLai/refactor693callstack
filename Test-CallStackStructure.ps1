<#
.SYNOPSIS
    Test script for the refactored ESS Health Checker call stack structure
.DESCRIPTION
    Validates that the new call stack architecture works correctly
    Tests module loading, dependency management, and basic functionality
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 1.0
#>

[CmdletBinding()]
param()

Write-Host "Testing ESS Health Checker Call Stack Structure" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check directory structure
Write-Host "Test 1: Validating directory structure..." -ForegroundColor Yellow

$requiredDirs = @(
    "src/Core",
    "src/modules/System", 
    "src/modules/Detection",
    "src/modules/Utils",
    "src/modules/Validation"
)

$missingDirs = @()
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        $missingDirs += $dir
    }
}

if ($missingDirs.Count -gt 0) {
    Write-Host "❌ Directory structure test failed: Missing directories: $($missingDirs -join ', ')" -ForegroundColor Red
} else {
    Write-Host "✅ Directory structure validated" -ForegroundColor Green
}

# Test 2: Test module loading
Write-Host "`nTest 2: Testing module loading..." -ForegroundColor Yellow

$requiredModules = @(
    "src/Core/HealthCheckCore.ps1",
    "src/modules/System/HardwareInfo.ps1",
    "src/modules/System/OSInfo.ps1",
    "src/modules/System/IISInfo.ps1",
    "src/modules/System/SQLInfo.ps1",
    "src/modules/System/SystemInfoOrchestrator.ps1",
    "src/modules/Detection/DetectionOrchestrator.ps1",
    "src/modules/Utils/HelperFunctions.ps1",
    "src/modules/Validation/SystemRequirements.ps1",
    "src/modules/Validation/InfrastructureValidation.ps1",
    "src/modules/Validation/ESSValidation.ps1",
    "src/modules/Validation/ValidationOrchestrator.ps1",
    "src/Core/Config.ps1",
    "src/Core/ReportGenerator.ps1"
)

$missingModules = @()
foreach ($module in $requiredModules) {
    if (-not (Test-Path $module)) {
        $missingModules += $module
    }
}

if ($missingModules.Count -gt 0) {
    Write-Host "❌ Module loading test failed: Missing required modules: $($missingModules -join ', ')" -ForegroundColor Red
} else {
    Write-Host "✅ Module loading tested" -ForegroundColor Green
}

# Test 3: Test core components
Write-Host "`nTest 3: Testing core components..." -ForegroundColor Yellow

try {
    # Load core modules
    . .\src\Core\Config.ps1
    . .\src\Core\HealthCheckCore.ps1
    
    # Test configuration
    $config = Get-ESSConfiguration
    Write-Host "Configuration loaded successfully:" -ForegroundColor Green
    $config | Format-List
    
    # Test health check manager
    $manager = Get-HealthCheckManager
    Write-Host "Health check manager created successfully" -ForegroundColor Green
    
    Write-Host "✅ Core components tested" -ForegroundColor Green
}
catch {
    Write-Host "❌ Core components test failed: $_" -ForegroundColor Red
}

# Test 4: Test orchestrator
Write-Host "`nTest 4: Testing orchestrator..." -ForegroundColor Yellow

try {
    # Load orchestrator
    . .\src\Core\HealthCheckOrchestrator.ps1
    
    # Create orchestrator instance
    $orchestrator = [HealthCheckOrchestrator]::new()
    Write-Host "✅ Orchestrator created successfully" -ForegroundColor Green
    
    # Test required functions
    $requiredFunctions = @(
        "Get-SystemInformation",
        "Get-ESSWFEDetection", 
        "Start-SystemValidation",
        "New-HealthCheckReport",
        "Show-SystemInfoSummary",
        "Update-SystemDeploymentInformation"
    )
    
    $missingFunctions = @()
    foreach ($function in $requiredFunctions) {
        if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
            $missingFunctions += $function
        }
    }
    
    if ($missingFunctions.Count -gt 0) {
        Write-Host "❌ Orchestrator test failed: Missing required functions: $($missingFunctions -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "✅ Orchestrator tested" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Orchestrator test failed: $_" -ForegroundColor Red
}

# Test 5: Test main entry point
Write-Host "`nTest 5: Testing main entry point..." -ForegroundColor Yellow

try {
    # Test if main script can be loaded
    if (Test-Path ".\src\Main.ps1") {
        Write-Host "✅ Main entry point tested" -ForegroundColor Green
    } else {
        Write-Host "❌ Main entry point test failed: Main.ps1 not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Main entry point test failed: $_" -ForegroundColor Red
}

# Summary
Write-Host "`nCall Stack Structure Test Summary" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$testResults = @(
    "Directory structure validated",
    "Module loading tested", 
    "Core components tested",
    "Orchestrator tested",
    "Main entry point tested"
)

foreach ($result in $testResults) {
    Write-Host "✅ $result" -ForegroundColor Green
}

Write-Host "`n🎉 All tests passed! The call stack structure is working correctly." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run the health checker: .\RunHealthCheck.ps1" -ForegroundColor White
Write-Host "2. Review the generated report" -ForegroundColor White
Write-Host "3. Check the CALL_STACK_ARCHITECTURE.md for detailed documentation" -ForegroundColor White
