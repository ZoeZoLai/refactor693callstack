<#
.SYNOPSIS
    Build script to create a single bundled PowerShell script
.DESCRIPTION
    This script reads all PowerShell modules from the src directory and bundles them
    into a single PowerShell script that can then be converted to an executable
.NOTES
    Author: Assistant
    Date: September 11, 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "output\ESSHealthChecker-Complete.ps1",
    
    [Parameter(Mandatory = $false)]
    [string]$SourceDirectory = "..\src"
)

Write-Host "ESS Health Checker - Build Bundled Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check if source directory exists
if (-not (Test-Path $SourceDirectory)) {
    Write-Error "Source directory '$SourceDirectory' not found!"
    exit 1
}

# Define the module loading order (as per your Main.ps1)
$moduleOrder = @(
    # Core modules first (dependencies for other modules)
    "Core\HealthCheckCore.ps1",
    "Core\Config.ps1",
    
    # Utility modules
    "Utils\HelperFunctions.ps1",
    
    # System information modules (depends on Core modules)
    "SystemInfo\OSInfo.ps1",
    "SystemInfo\HardwareInfo.ps1", 
    "SystemInfo\IISInfo.ps1",
    "SystemInfo\SQLInfo.ps1",
    "SystemInfo\SystemInfoOrchestrator.ps1",
    
    # Validation modules (depends on SystemInfo modules)
    "Validation\SystemRequirements.ps1",
    "Validation\InfrastructureValidation.ps1",
    "Validation\ESSValidation.ps1",
    "Validation\ValidationOrchestrator.ps1",
    
    # Detection modules (depends on SystemInfo modules)
    "Detection\ESSDetection.ps1",
    "Detection\WFEDetection.ps1",
    "Detection\ESSHealthCheckAPI.ps1",
    "Detection\DetectionOrchestrator.ps1",
    
    # Report generation (depends on all other modules)
    "Core\ReportGenerator.ps1",
    
    # Interactive functionality (depends on all other modules)
    "Interactive\InteractiveHealthCheck.ps1",
    
    # Main entry point functions (must be last)
    "Main.ps1"
)

Write-Host "Creating bundled script: $OutputFile" -ForegroundColor Yellow

# Start building the bundled script
$bundledContent = @"
<#
.SYNOPSIS
    ESS Pre-Upgrade Health Checker - Complete Bundled Script
.DESCRIPTION
    Complete ESS Health Checker bundled into a single PowerShell script for conversion to executable
    All modules are embedded within this script - no external file dependencies
.NOTES
    Author: Zoe Lai (Original), Assistant (Bundler)
    Date: $(Get-Date -Format 'MMMM dd, yyyy')
    Version: 3.0 - Complete Bundled Single File
    
    This bundled script contains all modules from the original project structure.
    Generated automatically by Build-BundledScript.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = `$false)]
    [switch]`$Interactive,
    
    [Parameter(Mandatory = `$false)]
    [switch]`$NoConsole
)

# Set execution policy for this session if needed
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
}
catch {
    Write-Warning "Could not set execution policy: `$_"
}

# Set working directory for proper path resolution (mimic original launcher behavior)
`$scriptPath = if (`$MyInvocation.MyCommand.Path) {
    Split-Path -Parent `$MyInvocation.MyCommand.Path
} else {
    # Fallback for bundled executable
    Get-Location
}
Set-Location `$scriptPath

Write-Host "ESS Pre-Upgrade Health Checker - Bundled Version" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# EMBEDDED MODULES START HERE
# ============================================================================

"@

# Process each module in order
foreach ($modulePath in $moduleOrder) {
    $fullPath = Join-Path $SourceDirectory $modulePath
    
    if (Test-Path $fullPath) {
        Write-Host "Processing: $modulePath" -ForegroundColor Green
        
        # Read the module content
        $moduleContent = Get-Content $fullPath -Raw
        
        # Remove any dot-sourcing commands (they're not needed in bundled script)
        $moduleContent = $moduleContent -replace '(?m)^\s*\.\s+\.\\\S+.*\.ps1\s*$', ''
        
        # Add module separator and content
        $bundledContent += @"

# ===== $modulePath =====
$moduleContent

"@
    } else {
        Write-Warning "Module not found: $fullPath"
    }
}

# Add final initialization and execution logic
$bundledContent += @"

# ============================================================================
# BUNDLED SCRIPT INITIALIZATION COMPLETE
# ============================================================================

# ============================================================================
# BUNDLED EXECUTABLE CONFIGURATION
# ============================================================================

# Ensure Reports folder exists in current directory for bundled executable
`$bundledReportsPath = Join-Path (Get-Location) "Reports"
if (-not (Test-Path `$bundledReportsPath)) {
    New-Item -ItemType Directory -Path `$bundledReportsPath -Force | Out-Null
}

# ============================================================================
# MAIN EXECUTION LOGIC
# ============================================================================

try {
    if (`$Interactive) {
        # Run interactive mode
        Write-Host "Starting interactive health checks..." -ForegroundColor Yellow
        `$reportPath = Start-InteractiveESSHealthChecks
    } else {
        # Check if we need to show menu (when run without parameters)
        if (-not `$PSBoundParameters.ContainsKey('Interactive')) {
            # Display mode selection menu
            Write-Host "Please select the health check mode:" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "1. Automated Checker" -ForegroundColor White
            Write-Host "   - Runs complete automated health check process" -ForegroundColor Gray
            Write-Host ""
            Write-Host "2. Interactive Checker" -ForegroundColor White
            Write-Host "   - Allows selective instance checking" -ForegroundColor Gray
            Write-Host ""
            Write-Host "3. Exit" -ForegroundColor White
            Write-Host ""
            
            do {
                `$choice = Read-Host "Enter your choice (1, 2, or 3)"
                if (`$choice -notin @("1", "2", "3")) {
                    Write-Host "Invalid choice. Please enter 1, 2, or 3." -ForegroundColor Red
                }
            } while (`$choice -notin @("1", "2", "3"))
            
            Write-Host ""
            
            if (`$choice -eq "1") {
                # Run automated checker
                Write-Host "Starting automated health checks..." -ForegroundColor Yellow
                `$reportPath = Start-ESSHealthChecks
            }
            elseif (`$choice -eq "2") {
                # Run interactive checker
                Write-Host "Starting interactive health checks..." -ForegroundColor Yellow
                `$reportPath = Start-InteractiveESSHealthChecks
            }
            else {
                # Exit option
                Write-Host "Exiting health checker. Goodbye!" -ForegroundColor Yellow
                exit 0
            }
        } else {
            # Run automated mode
            Write-Host "Starting automated health checks..." -ForegroundColor Yellow
            `$reportPath = Start-ESSHealthChecks
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Health check completed successfully!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    # Check if we have a valid report path
    if (`$reportPath -and (`$reportPath -is [string]) -and `$reportPath.Trim()) {
        Write-Host "Report Location:" -ForegroundColor Cyan
        Write-Host "   `$reportPath" -ForegroundColor White
        Write-Host ""
        
        # Check if report file exists and show additional options
        if (Test-Path `$reportPath) {
            Write-Host "Next Steps:" -ForegroundColor Yellow
            Write-Host "   - Open report file to view detailed results" -ForegroundColor White
            Write-Host "   - Copy report path: `$reportPath" -ForegroundColor Gray
            Write-Host ""
            
            # Ask if user wants to open the report
            Write-Host "Would you like to open the report now? (Y/N): " -ForegroundColor Cyan -NoNewline
            try {
                `$openChoice = Read-Host
                if (`$openChoice -match '^[Yy]') {
                    Write-Host "Opening report..." -ForegroundColor Yellow
                    Start-Process `$reportPath
                    Start-Sleep -Seconds 2
                }
            } catch {
                # Fallback if Read-Host fails
                Write-Host ""
                Write-Host "You can manually open the report file at the location shown above." -ForegroundColor Gray
            }
        } else {
            Write-Host "Report Information:" -ForegroundColor Yellow
            Write-Host "   - Report was saved but file may not be accessible" -ForegroundColor White
            Write-Host "   - Check the Reports folder manually" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "Health Check Information:" -ForegroundColor Yellow
        Write-Host "   - Health check process completed" -ForegroundColor White
        Write-Host "   - Some operations may have been skipped due to missing instances" -ForegroundColor Gray
        Write-Host "   - For full functionality, ensure ESS/WFE is installed and run as Administrator" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host ""
    Write-Host "To run again:" -ForegroundColor Yellow
    Write-Host "   Run ESSHealthChecker.exe as administrator and select your option" -ForegroundColor White
    Write-Host ""
    
    # Enhanced pause mechanism with multiple fallbacks
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    try {
        # Try the primary method
        if (`$Host.UI.RawUI) {
            `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } else {
            # Fallback method
            `$null = Read-Host
        }
    } catch {
        # Final fallback - simple pause
        try {
            `$null = Read-Host "Press Enter to exit"
        } catch {
            # If all else fails, just pause briefly
            Write-Host "Application will close in 5 seconds..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
        }
    }
}
catch {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Error "An error occurred running the health check: `$_"
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   - Check if you have Administrator privileges" -ForegroundColor White
    Write-Host "   - Verify IIS is installed and accessible" -ForegroundColor White
    Write-Host "   - Ensure the Reports folder is writable" -ForegroundColor White
    Write-Host ""
    Write-Host "For help:" -ForegroundColor Cyan
    Write-Host "   - Check the README.md file" -ForegroundColor White
    Write-Host "   - Review the error message above" -ForegroundColor White
    Write-Host ""
    
    # Enhanced pause for error cases
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    try {
        if (`$Host.UI.RawUI) {
            `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } else {
            `$null = Read-Host
        }
    } catch {
        try {
            `$null = Read-Host "Press Enter to exit"
        } catch {
            Write-Host "Application will close in 10 seconds..." -ForegroundColor Gray
            Start-Sleep -Seconds 10
        }
    }
    exit 1
}
"@

# Write the bundled script
try {
    $bundledContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host ""
    Write-Host "Bundled script created successfully: $OutputFile" -ForegroundColor Green
    
    $fileSize = (Get-Item $OutputFile).Length
    Write-Host "File size: $([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Test the bundled script: .\$OutputFile" -ForegroundColor White
    Write-Host "2. Install PS2EXE: Install-Module ps2exe" -ForegroundColor White
    Write-Host "3. Convert to EXE: ps2exe -inputFile '$OutputFile' -outputFile 'ESSHealthChecker.exe' -verbose" -ForegroundColor White
} catch {
    Write-Error "Failed to write bundled script: $_"
    exit 1
}
