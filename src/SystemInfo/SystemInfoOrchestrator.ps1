<#
.SYNOPSIS
    System information collection orchestrator
.DESCRIPTION
    Coordinates collection of all system information including OS, hardware, IIS, SQL Server, and registry
    Following call stack principles with dependency injection
.NOTES
    Author: Zoe Lai
    Date: 30/07/2025
    Version: 2.0
#>

class SystemInformationManager {
    [hashtable]$SystemInfo
    [hashtable]$Configuration
    
    SystemInformationManager() {
        $this.SystemInfo = @{}
        $this.Configuration = @{}
    }
    
    [hashtable]CollectSystemInformation() {
        Write-Host "Gathering system information..." -ForegroundColor Yellow
        
        try {
            Write-Host "  Collecting basic system information..." -ForegroundColor Cyan
            $this.SystemInfo = @{
                # Basic system information
                ComputerName = $env:COMPUTERNAME
                Domain = $env:USERDOMAIN
                UserName = $env:USERNAME
                IsElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            }
            
            Write-Host "  Collecting OS information..." -ForegroundColor Cyan
            $this.SystemInfo.OS = Get-OSInformation
            
            Write-Host "  Collecting hardware information..." -ForegroundColor Cyan
            $this.SystemInfo.Hardware = Get-HardwareInformation
            
            Write-Host "  Collecting network information..." -ForegroundColor Cyan
            $this.SystemInfo.Network = Get-NetworkInformation
            
            Write-Host "  Collecting IIS information..." -ForegroundColor Cyan
            $this.SystemInfo.IIS = Get-IISInformation
            
            Write-Host "  Collecting registry information..." -ForegroundColor Cyan
            $this.SystemInfo.Registry = Get-RegistryInformation
            
            Write-Host "  Collecting SQL Server information..." -ForegroundColor Cyan
            $this.SystemInfo.SQLServer = Get-SQLServerInformation
            
            # Deployment structure will be populated later
            $this.SystemInfo.DeploymentStructure = $null
            
            # Timestamp
            $this.SystemInfo.CollectedAt = Get-Date
            
            # Initialize ESS and WFE information
            $this.SystemInfo.ESS = @{ Installed = $false }
            $this.SystemInfo.WFE = @{ Installed = $false }
            
            Write-Host "System information collection completed successfully" -ForegroundColor Green
            return $this.SystemInfo
        }
        catch {
            Write-Error "Failed to gather system information: $_"
            throw
        }
    }
    
    [object]GetSystemInfoValue([string]$Path) {
        if (-not $this.SystemInfo -or $this.SystemInfo.Count -eq 0) {
            Write-Warning "System information not available. Please run CollectSystemInformation first."
            return $null
        }
        
        try {
            $value = $this.SystemInfo
            $pathParts = $Path.Split('.')
            
            foreach ($part in $pathParts) {
                $value = $value.$part
                if ($null -eq $value) {
                    Write-Warning "Value not found for path '$Path'."
                    return $null
                }
            }
            return $value
        }
        catch {
            Write-Warning "Could not retrieve system info value for path '$Path': $_"
            return $null
        }
    }
    
    [void]UpdateDeploymentInformation([hashtable]$DetectionResults) {
        if ($DetectionResults) {
            $this.SystemInfo.DeploymentStructure = $DetectionResults.DeploymentType
            $this.SystemInfo.ESS.Installed = $DetectionResults.ESSInstances.Count -gt 0
            $this.SystemInfo.WFE.Installed = $DetectionResults.WFEInstances.Count -gt 0
        }
    }
}


function Get-SystemInformation {
    <#
    .SYNOPSIS
        Gathers system information for the ESS Health Checker
    .DESCRIPTION
        Collects detailed system information including OS version, hardware, IIS, database connections,
        and more for use in configuration and health checks
    .PARAMETER SystemInfoManager
        SystemInformationManager instance for system information operations
    .RETURNS
        PSCustomObject containing system information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$SystemInfoManager
    )
    
    return $SystemInfoManager.CollectSystemInformation()
}



