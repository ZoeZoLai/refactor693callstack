<#
.SYNOPSIS
    ESS Health Checker - Requirements Installation and Verification Script
.DESCRIPTION
    Automatically checks, installs, and verifies all requirements for the ESS Pre-Upgrade Health Checker
.PARAMETER CheckOnly
    Only check requirements without installing anything
.PARAMETER SkipOptional
    Skip installation of optional modules
.PARAMETER Force
    Force installation even if requirements appear to be met
.NOTES
    Author: ESS Health Checker Team
    Date: September 12, 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$CheckOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipOptional,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Write-Host "ESS Health Checker - Requirements Installation" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Track installation results
$results = @{
    PowerShellVersion = $false
    OperatingSystem = $false
    ExecutionPolicy = $false
    IISModules = $false
    BuildModules = $false
    OptionalModules = $false
    WindowsFeatures = $false
    Privileges = $false
}

# ============================================================================
# Helper Functions
# ============================================================================

function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-StatusMessage {
    param(
        [string]$Component,
        [string]$Status,
        [string]$Message
    )
    
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$Status] $Component : $Message" -ForegroundColor $color
}

# ============================================================================
# Requirement Checks
# ============================================================================

Write-Host "Step 1: Checking PowerShell Version..." -ForegroundColor Yellow

try {
    $psVersion = $PSVersionTable.PSVersion
    $isCompatible = $psVersion.Major -ge 5 -and ($psVersion.Major -gt 5 -or $psVersion.Minor -ge 1)
    
    if ($isCompatible) {
        Write-StatusMessage "PowerShell Version" "PASS" "PowerShell $($psVersion.ToString()) is compatible"
        $results.PowerShellVersion = $true
    } else {
        Write-StatusMessage "PowerShell Version" "FAIL" "PowerShell $($psVersion.ToString()) is not compatible. Minimum required: 5.1"
        throw "Incompatible PowerShell version"
    }
} catch {
    Write-StatusMessage "PowerShell Version" "FAIL" "Could not determine PowerShell version: $_"
}

Write-Host ""
Write-Host "Step 2: Checking Operating System..." -ForegroundColor Yellow

try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $osName = $os.Caption
    $osVersion = [Version]$os.Version
    
    # Check for Windows 10+ or Windows Server 2016+
    $isCompatible = $false
    if ($osName -like "*Windows 10*" -or $osName -like "*Windows 11*") {
        $isCompatible = $true
    } elseif ($osName -like "*Windows Server*") {
        # Windows Server 2016 is version 10.0.14393
        $isCompatible = $osVersion.Major -ge 10
    }
    
    if ($isCompatible) {
        Write-StatusMessage "Operating System" "PASS" "$osName (Version $($osVersion.ToString())) is compatible"
        $results.OperatingSystem = $true
    } else {
        Write-StatusMessage "Operating System" "WARN" "$osName may not be fully compatible. Recommended: Windows Server 2016+ or Windows 10+"
        $results.OperatingSystem = $true  # Allow with warning
    }
} catch {
    Write-StatusMessage "Operating System" "FAIL" "Could not determine OS version: $_"
}

Write-Host ""
Write-Host "Step 3: Checking Administrator Privileges..." -ForegroundColor Yellow

try {
    if (Test-IsAdministrator) {
        Write-StatusMessage "Administrator Rights" "PASS" "Running with Administrator privileges"
        $results.Privileges = $true
    } else {
        Write-StatusMessage "Administrator Rights" "WARN" "Not running as Administrator. Some features may not work properly"
        Write-Host "  Recommendation: Re-run this script as Administrator" -ForegroundColor Gray
    }
} catch {
    Write-StatusMessage "Administrator Rights" "FAIL" "Could not check Administrator privileges: $_"
}

Write-Host ""
Write-Host "Step 4: Checking PowerShell Execution Policy..." -ForegroundColor Yellow

try {
    $executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    
    if ($executionPolicy -in @('RemoteSigned', 'Unrestricted', 'Bypass')) {
        Write-StatusMessage "Execution Policy" "PASS" "Execution policy '$executionPolicy' allows script execution"
        $results.ExecutionPolicy = $true
    } else {
        if (-not $CheckOnly) {
            Write-StatusMessage "Execution Policy" "INFO" "Setting execution policy to RemoteSigned for CurrentUser"
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                Write-StatusMessage "Execution Policy" "PASS" "Execution policy set to RemoteSigned"
                $results.ExecutionPolicy = $true
            } catch {
                Write-StatusMessage "Execution Policy" "WARN" "Could not set execution policy: $_"
            }
        } else {
            Write-StatusMessage "Execution Policy" "WARN" "Execution policy '$executionPolicy' may prevent script execution"
        }
    }
} catch {
    Write-StatusMessage "Execution Policy" "FAIL" "Could not check execution policy: $_"
}

Write-Host ""
Write-Host "Step 5: Checking IIS Modules..." -ForegroundColor Yellow

try {
    # Check WebAdministration module
    $webAdminModule = Get-Module -ListAvailable -Name WebAdministration
    if ($webAdminModule) {
        Write-StatusMessage "WebAdministration Module" "PASS" "Module available (Version: $($webAdminModule.Version))"
    } else {
        Write-StatusMessage "WebAdministration Module" "WARN" "Module not found. Install IIS Management Tools"
    }
    
    # Check IISAdministration module
    $iisAdminModule = Get-Module -ListAvailable -Name IISAdministration
    if ($iisAdminModule) {
        Write-StatusMessage "IISAdministration Module" "PASS" "Module available (Version: $($iisAdminModule.Version))"
    } else {
        Write-StatusMessage "IISAdministration Module" "WARN" "Module not found. Install IIS Management Tools"
    }
    
    if ($webAdminModule -and $iisAdminModule) {
        $results.IISModules = $true
    }
} catch {
    Write-StatusMessage "IIS Modules" "FAIL" "Could not check IIS modules: $_"
}

Write-Host ""
Write-Host "Step 6: Checking Build Dependencies..." -ForegroundColor Yellow

try {
    # Check PS2EXE module (for building executable)
    $ps2exeModule = Get-Module -ListAvailable -Name ps2exe
    if ($ps2exeModule) {
        Write-StatusMessage "PS2EXE Module" "PASS" "Build module available (Version: $($ps2exeModule.Version))"
        $results.BuildModules = $true
    } else {
        if (-not $CheckOnly -and -not $SkipOptional) {
            Write-StatusMessage "PS2EXE Module" "INFO" "Installing PS2EXE module for executable building..."
            try {
                Install-Module ps2exe -Force -Scope CurrentUser -AllowClobber
                Write-StatusMessage "PS2EXE Module" "PASS" "PS2EXE module installed successfully"
                $results.BuildModules = $true
            } catch {
                Write-StatusMessage "PS2EXE Module" "WARN" "Could not install PS2EXE module: $_"
            }
        } else {
            Write-StatusMessage "PS2EXE Module" "INFO" "PS2EXE module not installed (needed for building executable)"
        }
    }
} catch {
    Write-StatusMessage "Build Dependencies" "FAIL" "Could not check build dependencies: $_"
}

if (-not $SkipOptional) {
    Write-Host ""
    Write-Host "Step 7: Checking Optional Modules..." -ForegroundColor Yellow
    
    try {
        # Check SqlServer module (optional)
        $sqlModule = Get-Module -ListAvailable -Name SqlServer
        if ($sqlModule) {
            Write-StatusMessage "SqlServer Module" "PASS" "Optional SQL module available (Version: $($sqlModule.Version))"
            $results.OptionalModules = $true
        } else {
            Write-StatusMessage "SqlServer Module" "INFO" "Optional SQL Server module not installed (enhances SQL connectivity)"
            $results.OptionalModules = $true  # Not required
        }
    } catch {
        Write-StatusMessage "Optional Modules" "INFO" "Could not check optional modules: $_"
        $results.OptionalModules = $true  # Not required
    }
}

Write-Host ""
Write-Host "Step 8: Checking Windows Features..." -ForegroundColor Yellow

try {
    # Check if IIS is installed
    $iisFeature = Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -ErrorAction SilentlyContinue
    if ($iisFeature -and $iisFeature.State -eq 'Enabled') {
        Write-StatusMessage "IIS Web Server" "PASS" "IIS Web Server Role is installed"
        $results.WindowsFeatures = $true
    } else {
        Write-StatusMessage "IIS Web Server" "WARN" "IIS Web Server Role not detected. Required for ESS/WFE detection"
        Write-Host "  To install: Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole" -ForegroundColor Gray
    }
} catch {
    Write-StatusMessage "Windows Features" "INFO" "Could not check Windows features (may require Administrator rights)"
}

# ============================================================================
# Summary Report
# ============================================================================

Write-Host ""
Write-Host "Requirements Summary" -ForegroundColor Magenta
Write-Host "===================" -ForegroundColor Magenta

$totalChecks = $results.Count
$passedChecks = ($results.Values | Where-Object { $_ -eq $true }).Count
$passPercentage = [math]::Round(($passedChecks / $totalChecks) * 100, 1)

Write-Host ""
Write-Host "Overall Status: $passedChecks/$totalChecks checks passed ($passPercentage%)" -ForegroundColor Cyan

Write-Host ""
Write-Host "Component Status:" -ForegroundColor White
foreach ($component in $results.GetEnumerator()) {
    $status = if ($component.Value) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($component.Value) { "Green" } else { "Red" }
    Write-Host "  $($component.Key): $status" -ForegroundColor $color
}

Write-Host ""
if ($passedChecks -eq $totalChecks) {
    Write-Host "🎉 All requirements met! ESS Health Checker is ready to use." -ForegroundColor Green
} elseif ($passedChecks -ge ($totalChecks * 0.8)) {
    Write-Host "⚠️  Most requirements met. ESS Health Checker should work with minor limitations." -ForegroundColor Yellow
} else {
    Write-Host "❌ Several requirements not met. ESS Health Checker may not work properly." -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
if ($results.BuildModules) {
    Write-Host "  • Build executable: .\Build-Executable.ps1" -ForegroundColor White
} else {
    Write-Host "  • Install PS2EXE: Install-Module ps2exe" -ForegroundColor White
}
Write-Host "  • Run health checker: .\RunHealthCheck.ps1" -ForegroundColor White
Write-Host "  • Run interactive mode: .\RunInteractiveHealthCheck.ps1" -ForegroundColor White

Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  • README.md - Usage instructions" -ForegroundColor White
Write-Host "  • RUNBOOK_BUILD_PROCESS.md - Build documentation" -ForegroundColor White
Write-Host "  • requirements.txt - Detailed requirements" -ForegroundColor White

# Return appropriate exit code
if ($passedChecks -ge ($totalChecks * 0.8)) {
    exit 0  # Success
} else {
    exit 1  # Requirements not met
}
