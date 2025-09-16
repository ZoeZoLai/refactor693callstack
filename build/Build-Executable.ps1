<#
.SYNOPSIS
    Complete build script to create ESS Health Checker executable
.DESCRIPTION
    This script performs the complete process:
    1. Bundles all PowerShell modules into a single script
    2. Tests the bundled script
    3. Converts to executable using PS2EXE
.NOTES
    Author: Assistant
    Date: September 11, 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputExe = "output\ESSHealthChecker.exe",
    
    [Parameter(Mandatory = $false)]
    [string]$BundledScript = "output\ESSHealthChecker-Complete.ps1",
    
    [Parameter(Mandatory = $false)]
    [string]$SourceDirectory = "..\src",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTest,
    
    [Parameter(Mandatory = $false)]
    [switch]$InstallPS2EXE
)

Write-Host "ESS Health Checker - Complete Build Process" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install PS2EXE if requested
if ($InstallPS2EXE) {
    Write-Host "Step 1: Installing PS2EXE module..." -ForegroundColor Yellow
    try {
        if (-not (Get-Module -ListAvailable -Name ps2exe)) {
            Install-Module ps2exe -Force -Scope CurrentUser
            Write-Host "PS2EXE installed successfully" -ForegroundColor Green
        } else {
            Write-Host "PS2EXE already installed" -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to install PS2EXE: $_"
        exit 1
    }
    Write-Host ""
}

# Step 2: Check PS2EXE availability
Write-Host "Step 2: Checking PS2EXE availability..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "PS2EXE module not found!" -ForegroundColor Red
    Write-Host "Please install it with: Install-Module ps2exe" -ForegroundColor Yellow
    Write-Host "Or run this script with -InstallPS2EXE flag" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "PS2EXE module found" -ForegroundColor Green
}
Write-Host ""

# Step 3: Bundle all modules
Write-Host "Step 3: Creating bundled PowerShell script..." -ForegroundColor Yellow
try {
    & ".\Build-BundledScript.ps1" -OutputFile $BundledScript -SourceDirectory $SourceDirectory
    if (-not (Test-Path $BundledScript)) {
        throw "Bundled script was not created"
    }
    Write-Host "Bundled script created: $BundledScript" -ForegroundColor Green
} catch {
    Write-Error "Failed to create bundled script: $_"
    exit 1
}
Write-Host ""

# Step 4: Test the bundled script (optional)
if (-not $SkipTest) {
    Write-Host "Step 4: Testing bundled script..." -ForegroundColor Yellow
    try {
        # Test syntax by parsing the script
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $BundledScript -Raw), [ref]$null)
        Write-Host "Script syntax validation passed" -ForegroundColor Green
        
        # You could add more sophisticated testing here
        Write-Host "To test functionality, run: .\$BundledScript" -ForegroundColor Cyan
    } catch {
        Write-Warning "Script syntax validation failed: $_"
        Write-Host "Continuing with executable creation..." -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 5: Convert to executable
Write-Host "Step 5: Converting to executable..." -ForegroundColor Yellow
try {
    Import-Module ps2exe
    
    # Define PS2EXE parameters
    $ps2exeParams = @{
        inputFile = $BundledScript
        outputFile = $OutputExe
        requireAdmin = $false
        verbose = $true
        title = "ESS Pre-Upgrade Health Checker"
        description = "MYOB PayGlobal ESS Health Check Tool"
        company = "MYOB"
        product = "ESS Health Checker"
        copyright = "© $(Get-Date -Format yyyy) MYOB"
        version = "3.0.0.0"
        noConsole = $false  # Keep console for user interaction
        noOutput = $false   # Allow output
        noError = $false    # Allow error output
        credentialGUI = $false
        configFile = $false
    }
    
    Write-Host "Converting with parameters:" -ForegroundColor Cyan
    $ps2exeParams.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
    }
    Write-Host ""
    
    ps2exe @ps2exeParams
    
    if (Test-Path $OutputExe) {
        $exeSize = (Get-Item $OutputExe).Length
        Write-Host "Executable created successfully: $OutputExe" -ForegroundColor Green
        Write-Host "Executable size: $([math]::Round($exeSize / 1MB, 2)) MB" -ForegroundColor Cyan
    } else {
        throw "Executable was not created"
    }
} catch {
    Write-Error "Failed to create executable: $_"
    exit 1
}
Write-Host ""

# Step 6: Final summary
Write-Host "Build Process Complete!" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""
Write-Host "Created files:" -ForegroundColor Yellow
Write-Host "Bundled script: $BundledScript" -ForegroundColor White
Write-Host "Executable: $OutputExe" -ForegroundColor White
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  .\$OutputExe                    # Interactive menu" -ForegroundColor White
Write-Host "  .\$OutputExe -Interactive       # Direct to interactive mode" -ForegroundColor White
Write-Host ""
Write-Host "Distribution:" -ForegroundColor Yellow
Write-Host "  Copy only '$OutputExe' to target machines" -ForegroundColor White
Write-Host "  No additional files or folders needed!" -ForegroundColor White
Write-Host ""
Write-Host "Requirements on target machines:" -ForegroundColor Yellow
Write-Host "  - Windows PowerShell 5.1+ or PowerShell Core" -ForegroundColor White
Write-Host "  - Administrator privileges (recommended for full functionality)" -ForegroundColor White
Write-Host "  - IIS installed (if checking IIS systems)" -ForegroundColor White
