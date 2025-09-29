<#
.SYNOPSIS
    Interactive launcher script for ESS Pre-Upgrade Health Checker
.DESCRIPTION
    This script provides an interactive interface for the ESS Health Checker with three options:
    1. Automated checker - runs the full automated health check process
    2. Interactive checker - allows selective instance checking with user input
    3. Exit - exit the health checker application
.NOTES
    Author: Zoe Lai
    Date: 09/01/2025
    Version: 1.0 - Interactive Mode
#>

[CmdletBinding()]
param()

# Set execution policy for this session if needed
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
}
catch {
    Write-Warning "Could not set execution policy: $_"
}

# Change to script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "ESS Pre-Upgrade Health Checker - Interactive Mode" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Import the main script
    $srcPath = Join-Path $scriptPath "src"
    if (Test-Path $srcPath) {
        Set-Location $srcPath
        . .\Main.ps1
        
        # Display mode selection menu
        Write-Host "Please select the health check mode:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Automated Checker" -ForegroundColor White
        Write-Host "   - Runs complete automated health check process" -ForegroundColor Gray
        Write-Host "   - Checks all detected ESS/WFE instances automatically" -ForegroundColor Gray
        Write-Host "   - Generates comprehensive report for all instances" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Interactive Checker" -ForegroundColor White
        Write-Host "   - Allows selective instance checking" -ForegroundColor Gray
        Write-Host "   - Prompts for ESS URL input for API health checks" -ForegroundColor Gray
        Write-Host "   - Generates targeted report for selected instances only" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. Exit" -ForegroundColor White
        Write-Host "   - Exit the health checker application" -ForegroundColor Gray
        Write-Host ""
        
        do {
            $choice = Read-Host "Enter your choice (1, 2, or 3)"
            if ($choice -notin @("1", "2", "3")) {
                Write-Host "Invalid choice. Please enter 1, 2, or 3." -ForegroundColor Red
            }
        } while ($choice -notin @("1", "2", "3"))
        
        Write-Host ""
        
        if ($choice -eq "1") {
            # Run automated checker
            Write-Host "Starting automated health checks..." -ForegroundColor Yellow
            $reportPath = Start-ESSHealthChecks
            
            
            Write-Host ""
            Write-Host "Health check completed successfully!" -ForegroundColor Green
            Write-Host "Report location: $reportPath" -ForegroundColor Cyan
        }
        elseif ($choice -eq "2") {
            # Run interactive checker
            Write-Host "Starting interactive health checks..." -ForegroundColor Yellow
            $reportPath = Start-InteractiveESSHealthChecks
            
           
            Write-Host ""
            Write-Host "Health check completed successfully!" -ForegroundColor Green
            Write-Host "Report location: $reportPath" -ForegroundColor Cyan
        }
        else {
            # Exit option
            Write-Host "Exiting health checker. Goodbye!" -ForegroundColor Yellow
            exit 0
        }
        
    } else {
        throw "Source directory not found at: $srcPath"
    }
    
    # Pause to let user see results
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Error "An error occurred running the health check: $_"
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
