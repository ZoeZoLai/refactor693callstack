# SimpleTest.ps1
# Simple functionality test for ESS Pre-Upgrade Health Checker
# Tests individual functions without loading the whole tool

Write-Host "=== ESS Health Checker - Individual Function Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Load individual modules directly
Write-Host "Test 1: Loading individual modules..." -ForegroundColor Yellow
try {
    # Load Core modules (go up one level from tests directory)
    . .\..\Core\Config.ps1
    . .\..\Core\HealthCheckCore.ps1
    . .\..\Core\ReportGenerator.ps1
    
    # Load SystemInfo modules
    . .\..\SystemInfo\OSInfo.ps1
    . .\..\SystemInfo\HardwareInfo.ps1
    . .\..\SystemInfo\IISInfo.ps1
    . .\..\SystemInfo\SQLInfo.ps1
    . .\..\SystemInfo\SystemInfoOrchestrator.ps1
    
    # Load Utils
    . .\..\Utils\HelperFunctions.ps1
    
    Write-Host "[PASS] Individual modules loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Failed to load modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Test individual functions
Write-Host ""
Write-Host "Test 2: Testing individual functions..." -ForegroundColor Yellow

# Test configuration creation
Write-Host "  Testing New-ESSConfiguration..." -ForegroundColor Cyan
try {
    $config = New-ESSConfiguration
    if ($config -and $config.MinimumRequirements) {
        Write-Host "  [PASS] Configuration created successfully" -ForegroundColor Green
        Write-Host "    - Minimum Memory: $($config.MinimumRequirements.MinimumMemoryGB) GB" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Configuration creation failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Configuration test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test result manager creation
Write-Host "  Testing Get-HealthCheckManager..." -ForegroundColor Cyan
try {
    $resultManager = Get-HealthCheckManager
    if ($resultManager) {
        Write-Host "  [PASS] Result manager created successfully" -ForegroundColor Green
        Write-Host "    - Initial result count: $($resultManager.GetResults().Count)" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Result manager creation failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Result manager test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test OS information
Write-Host "  Testing Get-OSInformation..." -ForegroundColor Cyan
try {
    $osInfo = Get-OSInformation
    if ($osInfo -and $osInfo.Version) {
        Write-Host "  [PASS] OS information collected successfully" -ForegroundColor Green
        Write-Host "    - OS Version: $($osInfo.Version)" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] OS information collection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] OS information test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test hardware information
Write-Host "  Testing Get-HardwareInformation..." -ForegroundColor Cyan
try {
    $hardwareInfo = Get-HardwareInformation
    if ($hardwareInfo -and $hardwareInfo.TotalMemoryGB) {
        Write-Host "  [PASS] Hardware information collected successfully" -ForegroundColor Green
        Write-Host "    - Total Memory: $([math]::Round($hardwareInfo.TotalMemoryGB, 2)) GB" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Hardware information collection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Hardware information test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test helper functions
Write-Host "  Testing Get-AppPoolIdentity..." -ForegroundColor Cyan
try {
    $poolIdentity = Get-AppPoolIdentity -AppPoolName "TestPool"
    if ($poolIdentity -ne $null) {
        Write-Host "  [PASS] Helper function working" -ForegroundColor Green
        Write-Host "    - App Pool Identity test: $poolIdentity" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] Helper function failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Helper function test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "All basic functionality tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the full health check, use:" -ForegroundColor Yellow
Write-Host "  .\RunHealthCheck.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To run with verbose output:" -ForegroundColor Yellow
Write-Host "  .\RunHealthCheck.ps1 -Verbose" -ForegroundColor White
Write-Host ""
