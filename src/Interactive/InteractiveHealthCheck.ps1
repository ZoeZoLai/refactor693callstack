<#
.SYNOPSIS
    Interactive health check functionality
.DESCRIPTION
    Provides interactive functions for selective instance checking and user input handling
    Following call stack principles with dependency injection
.NOTES
    Author: Zoe Lai
    Date: 09/01/2025
    Version: 1.0 - Interactive Mode
#>

function Show-InstanceSelectionMenu {
    <#
    .SYNOPSIS
        Displays available ESS and WFE instances for user selection
    .DESCRIPTION
        Shows a numbered menu of all detected ESS and WFE instances with high-level details
        and allows users to select specific instances for health checking
    .PARAMETER DetectionResults
        Detection results containing ESS and WFE instances
    .RETURNS
        Object containing selected instances
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectionResults
    )
    
    try {
        Write-Host "`n=== Available ESS and WFE Instances ===" -ForegroundColor Cyan
        Write-Host ""
        
        $allInstances = @()
        $instanceCounter = 1
        
        # Display ESS instances
        if ($DetectionResults.ESSInstances -and $DetectionResults.ESSInstances.Count -gt 0) {
            Write-Host "ESS Instances:" -ForegroundColor Yellow
            
            # Create table data for ESS instances
            $essTableData = @()
            foreach ($ess in $DetectionResults.ESSInstances) {
                $instanceInfo = @{
                    Index = $instanceCounter
                    Type = "ESS"
                    SiteName = $ess.SiteName
                    ApplicationPath = $ess.ApplicationPath
                    DatabaseServer = $ess.DatabaseServer
                    DatabaseName = $ess.DatabaseName
                    TenantID = $ess.TenantID
                    Instance = $ess
                }
                
                $essTableData += [PSCustomObject]@{
                    '#' = $instanceCounter
                    'Type' = 'ESS'
                    'Site' = $ess.SiteName
                    'Path' = $ess.ApplicationPath
                    'Database' = "$($ess.DatabaseServer)/$($ess.DatabaseName)"
                    'Tenant ID' = if ($ess.TenantID) { $ess.TenantID.Substring(0, 8) + "..." } else { "N/A" }
                }
                
                $allInstances += $instanceInfo
                $instanceCounter++
            }
            
            # Display ESS instances in table format
            $essTableData | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ -ForegroundColor White }
            Write-Host ""
        } else {
            Write-Host "No ESS instances found." -ForegroundColor Yellow
            Write-Host ""
        }
        
        # Display WFE instances
        if ($DetectionResults.WFEInstances -and $DetectionResults.WFEInstances.Count -gt 0) {
            Write-Host "WFE Instances:" -ForegroundColor Yellow
            
            # Create table data for WFE instances
            $wfeTableData = @()
            foreach ($wfe in $DetectionResults.WFEInstances) {
                $instanceInfo = @{
                    Index = $instanceCounter
                    Type = "WFE"
                    SiteName = $wfe.SiteName
                    ApplicationPath = $wfe.ApplicationPath
                    DatabaseServer = $wfe.DatabaseServer
                    DatabaseName = $wfe.DatabaseName
                    TenantID = $wfe.TenantID
                    Instance = $wfe
                }
                
                $wfeTableData += [PSCustomObject]@{
                    '#' = $instanceCounter
                    'Type' = 'WFE'
                    'Site' = $wfe.SiteName
                    'Path' = $wfe.ApplicationPath
                    'Database' = "$($wfe.DatabaseServer)/$($wfe.DatabaseName)"
                    'Tenant ID' = if ($wfe.TenantID) { $wfe.TenantID.Substring(0, 8) + "..." } else { "N/A" }
                }
                
                $allInstances += $instanceInfo
                $instanceCounter++
            }
            
            # Display WFE instances in table format
            $wfeTableData | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ -ForegroundColor White }
            Write-Host ""
        } else {
            Write-Host "No WFE instances found." -ForegroundColor Yellow
            Write-Host ""
        }
        
        if ($allInstances.Count -eq 0) {
            Write-Host "No ESS or WFE instances detected. Cannot proceed with interactive health check." -ForegroundColor Red
            return @{
                ESSInstances = @()
                WFEInstances = @()
            }
        }
        
        # Get user selection
        Write-Host "Please select the instances you would like to check:" -ForegroundColor Yellow
        Write-Host "Enter instance numbers separated by commas (e.g., 1,3,5)" -ForegroundColor Gray
        Write-Host "Or enter 'all' to select all instances" -ForegroundColor Gray
        Write-Host ""
        
        do {
            $selection = Read-Host "Your selection"
            
            if ($selection -eq "all") {
                $selectedIndices = 1..$allInstances.Count
                break
            }
            
            # Parse comma-separated numbers
            $selectedIndices = @()
            $validSelection = $true
            
            $numbers = $selection -split ',' | ForEach-Object { $_.Trim() }
            foreach ($number in $numbers) {
                if ($number -match '^\d+$') {
                    $index = [int]$number
                    if ($index -ge 1 -and $index -le $allInstances.Count) {
                        $selectedIndices += $index
                    } else {
                        Write-Host "Invalid number: $number. Please enter numbers between 1 and $($allInstances.Count)." -ForegroundColor Red
                        $validSelection = $false
                        break
                    }
                } else {
                    Write-Host "Invalid input: $number. Please enter numbers separated by commas." -ForegroundColor Red
                    $validSelection = $false
                    break
                }
            }
            
            if ($validSelection -and $selectedIndices.Count -gt 0) {
                break
            } elseif ($validSelection) {
                Write-Host "No valid selections made. Please try again." -ForegroundColor Red
            }
        } while ($true)
        
        # Build selected instances object
        $selectedInstances = @{
            ESSInstances = @()
            WFEInstances = @()
        }
        
        foreach ($index in $selectedIndices) {
            $instanceInfo = $allInstances | Where-Object { $_.Index -eq $index }
            if ($instanceInfo) {
                if ($instanceInfo.Type -eq "ESS") {
                    $selectedInstances.ESSInstances += $instanceInfo.Instance
                } elseif ($instanceInfo.Type -eq "WFE") {
                    $selectedInstances.WFEInstances += $instanceInfo.Instance
                }
            }
        }
        
        # Display selection summary
        Write-Host ""
        Write-Host "Selected instances:" -ForegroundColor Green
        Write-Host "  ESS Instances: $($selectedInstances.ESSInstances.Count)" -ForegroundColor White
        Write-Host "  WFE Instances: $($selectedInstances.WFEInstances.Count)" -ForegroundColor White
        Write-Host ""
        
        return $selectedInstances
    }
    catch {
        Write-Error "Error in instance selection: $_"
        return @{
            ESSInstances = @()
            WFEInstances = @()
        }
    }
}

function Get-ESSURLInput {
    <#
    .SYNOPSIS
        Gets ESS URL input from user for API health checks
    .DESCRIPTION
        Prompts user to enter ESS URL for API health checks, with validation
    .PARAMETER SelectedInstances
        Selected instances object containing ESS instances
    .RETURNS
        ESS URL string or null if not provided
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SelectedInstances
    )
    
    try {
        # Only prompt for ESS URL if there are ESS instances selected
        if ($SelectedInstances.ESSInstances.Count -eq 0) {
            Write-Host "No ESS instances selected. Skipping ESS URL input." -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "ESS URL Configuration for API Health Checks" -ForegroundColor Cyan
        Write-Host "===========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "For ESS API health checks, please provide the ESS URL." -ForegroundColor Yellow
        Write-Host "This should be the base URL where the ESS application is accessible." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Gray
        Write-Host "  - http://localhost/Self-Service/NZ_ESS" -ForegroundColor Gray
        Write-Host "  - https://ess.company.com/Self-Service/NZ_ESS" -ForegroundColor Gray
        Write-Host "  - http://server01:8080/ESS" -ForegroundColor Gray
        Write-Host ""
        
        do {
            $essUrl = Read-Host "Enter ESS URL (or press Enter to skip)"
            
            if ([string]::IsNullOrWhiteSpace($essUrl)) {
                Write-Host "ESS URL skipped. API health checks will not be performed." -ForegroundColor Yellow
                return $null
            }
            
            # Basic URL validation
            if ($essUrl -match '^https?://[^\s]+$') {
                Write-Host "ESS URL accepted: $essUrl" -ForegroundColor Green
                return $essUrl.Trim()
            } else {
                Write-Host "Invalid URL format. Please enter a valid URL starting with http:// or https://" -ForegroundColor Red
            }
        } while ($true)
    }
    catch {
        Write-Error "Error getting ESS URL input: $_"
        return $null
    }
}

function Start-SelectiveSystemValidation {
    <#
    .SYNOPSIS
        Runs selective validation checks for chosen instances only
    .DESCRIPTION
        Performs validation checks only on the selected ESS/WFE instances and ESS URL
        Following call stack principles with dependency injection
    .PARAMETER SystemInfo
        System information object for validation
    .PARAMETER SelectedInstances
        Selected instances object containing ESS and WFE instances to validate
    .PARAMETER OriginalDetectionResults
        Original detection results containing all available instances (for proper validation messages)
    .PARAMETER ESSUrl
        ESS URL for API health checks
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    .PARAMETER ValidationManager
        ValidationManager instance for validation operations
    .RETURNS
        Array of validation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$SelectedInstances,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$OriginalDetectionResults = $null,
        
        [Parameter(Mandatory = $false)]
        [string]$ESSUrl = $null,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager,
        
        [Parameter(Mandatory = $true)]
        [object]$ValidationManager
    )
    
    try {
        Write-Host "Running selective validation checks..." -ForegroundColor Yellow
        
        # Create modified detection results with only selected instances
        $selectiveDetectionResults = @{
            IISInstalled = $true  # Assume IIS is installed if we have instances
            ESSInstances = $SelectedInstances.ESSInstances
            WFEInstances = $SelectedInstances.WFEInstances
            # Use original deployment type if available, otherwise determine from selected instances
            DeploymentType = if ($OriginalDetectionResults -and $OriginalDetectionResults.DeploymentType) {
                $OriginalDetectionResults.DeploymentType
            } elseif ($SelectedInstances.ESSInstances.Count -gt 0 -and $SelectedInstances.WFEInstances.Count -gt 0) {
                "Combined"
            } elseif ($SelectedInstances.ESSInstances.Count -gt 0) {
                "ESS Only"
            } elseif ($SelectedInstances.WFEInstances.Count -gt 0) {
                "WFE Only"
            } else {
                "None"
            }
            Summary = @()
        }
        
        # Add original detection results for proper validation messages
        if ($OriginalDetectionResults) {
            $selectiveDetectionResults.IsInteractiveReport = $true
            $selectiveDetectionResults.OriginalESSInstances = $OriginalDetectionResults.ESSInstances
            $selectiveDetectionResults.OriginalWFEInstances = $OriginalDetectionResults.WFEInstances
        }
        
        # Run basic system validation (always needed)
        if ($SystemInfo -and $SystemInfo.Count -gt 0) {
            Test-SystemRequirements -SystemInfo $SystemInfo -Configuration $null -Manager $Manager
            Test-IISConfiguration -SystemInfo $SystemInfo -Manager $Manager
            Test-NetworkConnectivity -SystemInfo $SystemInfo -Manager $Manager
            Test-SecurityPermissions -SystemInfo $SystemInfo -Manager $Manager
        }
        
        # Run common ESS/WFE validations (only once regardless of selection)
        if ($SelectedInstances.ESSInstances.Count -gt 0 -or $SelectedInstances.WFEInstances.Count -gt 0) {
            Write-Host "Running ESS/WFE detection and database connectivity checks..." -ForegroundColor Cyan
            Test-ESSWFEDetection -DetectionResults $selectiveDetectionResults -Manager $Manager
            Test-DatabaseConnectivity -DetectionResults $selectiveDetectionResults -Manager $Manager
        }
        
        # Run ESS-specific validations for selected ESS instances
        if ($SelectedInstances.ESSInstances.Count -gt 0) {
            Write-Host "Running ESS-specific validations..." -ForegroundColor Cyan
            Test-WebConfigEncryptionValidation -DetectionResults $selectiveDetectionResults -Manager $Manager
            Test-ESSVersionValidation -DetectionResults $selectiveDetectionResults -Configuration $null -Manager $Manager
            Test-ESSHTTPSValidation -DetectionResults $selectiveDetectionResults -Manager $Manager
        }
        
        # Run WFE-specific validations for selected WFE instances
        if ($SelectedInstances.WFEInstances.Count -gt 0) {
            Write-Host "Running WFE-specific validations..." -ForegroundColor Cyan
            # WFE-specific validations would go here if any exist
        }
        
        # Run ESS API health check if URL provided
        if ($ESSUrl -and $SelectedInstances.ESSInstances.Count -gt 0) {
            Write-Host "Running ESS API health check..." -ForegroundColor Cyan
            Test-ESSAPIHealthCheckWithURL -ESSUrl $ESSUrl -Manager $Manager
        }
        
        Write-Host "Selective validation completed." -ForegroundColor Green
        return Get-HealthCheckResults -Manager $Manager
    }
    catch {
        Write-Error "Error during selective system validation: $_"
        throw
    }
}

function Test-ESSAPIHealthCheckWithURL {
    <#
    .SYNOPSIS
        Performs ESS API health check using provided URL
    .DESCRIPTION
        Uses the provided ESS URL to perform API health checks
    .PARAMETER ESSUrl
        ESS URL for API health checks
    .PARAMETER Manager
        HealthCheckResultManager instance for result management
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ESSUrl,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager
    )
    
    try {
        Write-Verbose "Testing ESS API health check with URL: $ESSUrl"
        
        # Import the API health check functions (only needed in non-bundled context)
        # Check if we need to import modules based on whether functions are already available
        if (-not (Get-Command -Name "Test-ESSAPIHealth" -ErrorAction SilentlyContinue)) {
            # We're in source script mode, need to import the module
            $apiModulePath = Join-Path $PSScriptRoot "..\Detection\ESSHealthCheckAPI.ps1"
            if (Test-Path $apiModulePath) {
                . $apiModulePath
            } else {
                Add-HealthCheckResult -Category "ESS API Health Check" -Check "Module Loading" -Status "FAIL" -Message "ESSHealthCheckAPI.ps1 module not found at: $apiModulePath" -Manager $Manager
                return
            }
        }
        # In bundled executable, all modules are already loaded, so skip import
        
        # Parse the URL to extract components
        $uri = [System.Uri]$ESSUrl
        $siteName = "Custom Site"  # Default since we don't know the actual site name
        $applicationPath = $uri.AbsolutePath.TrimStart('/')
        
        if ([string]::IsNullOrEmpty($applicationPath)) {
            $applicationPath = "/"
        }
        
        # Determine protocol
        $protocol = $uri.Scheme.ToLower()
        
        # Get port if specified
        $port = if ($uri.Port -ne -1) { $uri.Port } else { $null }
        
        Write-Host "Performing API health check on: $ESSUrl" -ForegroundColor Gray
        
        # Perform the health check
        $healthCheck = Get-ESSHealthCheckViaAPI -SiteName $siteName -ApplicationPath $applicationPath -Protocol $protocol -Port $port -TimeoutSeconds 90 -MaxRetries 2 -RetryDelaySeconds 5
        
        # Add results to manager
        if ($healthCheck.Success) {
            $summaryMessage = "ESS API health check successful for $ESSUrl"
            if ($healthCheck.Summary) {
                $summaryMessage += ". Components: $($healthCheck.Summary.TotalComponents) total, $($healthCheck.Summary.HealthyComponents) healthy"
            }
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "Overall Status - $ESSUrl" -Status "PASS" -Message $summaryMessage -Manager $Manager
        } else {
            $errorMessage = "ESS API health check failed for $ESSUrl"
            if ($healthCheck.Error) {
                $errorMessage += ": $($healthCheck.Error)"
            }
            Add-HealthCheckResult -Category "ESS API Health Check" -Check "Overall Status - $ESSUrl" -Status "FAIL" -Message $errorMessage -Manager $Manager
        }
        
        # Add specific component results
        $components = @(
            @{ Name = "PayGlobal Database"; Data = $healthCheck.PayGlobalDatabase },
            @{ Name = "SelfService Software"; Data = $healthCheck.SelfServiceSoftware },
            @{ Name = "SelfService Database"; Data = $healthCheck.SelfServiceDatabase },
            @{ Name = "Bridge"; Data = $healthCheck.Bridge },
            @{ Name = "WFE Database"; Data = $healthCheck.WFEDatabase },
            @{ Name = "Bridge Communication"; Data = $healthCheck.BridgeCommunication },
            @{ Name = "Workflow Endpoints"; Data = $healthCheck.WorkflowEndpoints }
        )
        
        foreach ($component in $components) {
            if ($component.Data) {
                $status = if ($component.Data.Status -eq "Healthy") { "PASS" } else { "FAIL" }
                $message = "$($component.Name) is $($component.Data.Status)"
                if ($component.Data.Version) {
                    $message += " (v$($component.Data.Version))"
                }
                if ($component.Data.Messages) {
                    $message += ". Messages: $($component.Data.Messages -join ', ')"
                }
                
                Add-HealthCheckResult -Category "ESS API Components" -Check "$($component.Name) - $ESSUrl" -Status $status -Message $message -Manager $Manager
            }
        }
    }
    catch {
        Write-Error "Error during ESS API health check with URL: $_"
        Add-HealthCheckResult -Category "ESS API Health Check" -Check "API Health Check - $ESSUrl" -Status "FAIL" -Message "Error during API health check: $($_.Exception.Message)" -Manager $Manager
    }
}
