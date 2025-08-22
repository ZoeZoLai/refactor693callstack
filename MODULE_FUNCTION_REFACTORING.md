# Module Function Refactoring - Call Stack Principles

## Overview

This document explains how functions within modules have been refactored to follow proper call stack principles, eliminating global variable dependencies and implementing dependency injection.

## Problems Solved

### ❌ **Before: Global Variable Dependencies**
```powershell
# Functions relied on global variables
function Get-AppPoolIdentity {
    param([string]$AppPoolName)
    
    if ($global:SystemInfo.IIS.ApplicationPools) {
        $appPool = $global:SystemInfo.IIS.ApplicationPools | Where-Object { $_.Name -eq $AppPoolName }
        # ... implementation
    }
}
```

### ✅ **After: Dependency Injection**
```powershell
# Functions receive data as parameters
function Get-AppPoolIdentity {
    param(
        [string]$AppPoolName,
        [hashtable]$SystemInfo = $null
    )
    
    if ($SystemInfo -and $SystemInfo.IIS -and $SystemInfo.IIS.ApplicationPools) {
        $appPool = $SystemInfo.IIS.ApplicationPools | Where-Object { $_.Name -eq $AppPoolName }
        # ... implementation
    }
}
```

## Key Principles Applied

### 1. **Explicit Dependencies**
- Functions declare what data they need through parameters
- No hidden dependencies on global state
- Clear input/output contracts

### 2. **Dependency Injection**
- Data is passed into functions rather than accessed globally
- Functions can work with any valid data structure
- Enables testing with mock data

### 3. **Single Responsibility**
- Each function has one clear purpose
- Functions don't manage global state
- Focused on data transformation and validation

### 4. **Testability**
- Functions can be tested in isolation
- Dependencies can be mocked
- Clear interfaces make testing straightforward

## Refactored Modules

### 1. **System Information Module**

#### Before:
```powershell
# Global variable dependency
$global:SystemInfo = $null

function Get-SystemInfoValue {
    param([string]$Path)
    
    if (-not (Test-SystemInfoAvailability)) {
        return $null
    }
    
    $value = $global:SystemInfo
    # ... implementation
}
```

#### After:
```powershell
# Class-based manager with dependency injection
class SystemInformationManager {
    [hashtable]$SystemInfo
    
    [object]GetSystemInfoValue([string]$Path) {
        if (-not $this.SystemInfo -or $this.SystemInfo.Count -eq 0) {
            Write-Warning "System information not available."
            return $null
        }
        
        $value = $this.SystemInfo
        # ... implementation
    }
}

function Get-SystemInfoValue {
    param(
        [string]$Path,
        [hashtable]$SystemInfo = $null
    )
    
    if ($SystemInfo) {
        # Use provided system info
        # ... implementation
    } else {
        # Use manager's cached data
        $manager = Get-SystemInformationManager
        return $manager.GetSystemInfoValue($Path)
    }
}
```

### 2. **Detection Module**

#### Before:
```powershell
function Get-ESSWFEDetection {
    param()
    
    # Direct function calls without context
    $iisInstalled = Test-IISInstallation
    $essInstances = Find-ESSInstances
    $wfeInstances = Find-WFEInstances
    # ... implementation
}
```

#### After:
```powershell
class DetectionManager {
    [hashtable]DetectESSWFEDeployment([hashtable]$SystemInfo = $null) {
        # Use injected system info for enhanced detection
        $iisInstalled = Test-IISInstallation -SystemInfo $SystemInfo
        $essInstances = Find-ESSInstances -SystemInfo $SystemInfo
        $wfeInstances = Find-WFEInstances -SystemInfo $SystemInfo
        # ... implementation
    }
}

function Get-ESSWFEDetection {
    param([hashtable]$SystemInfo = $null)
    
    $manager = Get-DetectionManager
    return $manager.DetectESSWFEDeployment($SystemInfo)
}
```

### 3. **Utility Functions**

#### Before:
```powershell
function Show-SystemInfoSummary {
    param([bool]$ShowDeploymentInfo = $false)
    
    $sysInfo = $global:SystemInfo
    
    Write-Host "Computer Name: $($sysInfo.ComputerName)"
    # ... implementation using global variables
}
```

#### After:
```powershell
function Show-SystemInfoSummary {
    param(
        [hashtable]$SystemInfo,
        [hashtable]$DetectionResults = $null,
        [bool]$ShowDeploymentInfo = $false
    )
    
    Write-Host "Computer Name: $($SystemInfo.ComputerName)"
    # ... implementation using injected parameters
}
```

## Call Stack Flow

### **Before: Global State Dependencies**
```
Main.ps1
├── Get-SystemInformation() → Sets $global:SystemInfo
├── Get-ESSWFEDetection() → Uses $global:SystemInfo
├── Show-SystemInfoSummary() → Uses $global:SystemInfo
└── New-HealthCheckReport() → Uses $global:SystemInfo
```

### **After: Dependency Injection**
```
Main.ps1
├── Get-SystemInformation() → Returns SystemInfo
├── Get-ESSWFEDetection(SystemInfo) → Uses injected SystemInfo
├── Show-SystemInfoSummary(SystemInfo, DetectionResults) → Uses injected data
└── New-HealthCheckReport(Results, Configuration) → Uses injected Configuration
```

## Benefits Achieved

### 1. **Clear Data Flow**
- Data flows explicitly through function parameters
- No hidden dependencies on global state
- Easy to trace data origins

### 2. **Testability**
```powershell
# Test with mock data
$mockSystemInfo = @{
    ComputerName = "TEST-SERVER"
    OS = @{ Caption = "Windows Server 2019" }
    IIS = @{ IsInstalled = $true }
}

$result = Get-AppPoolIdentity -AppPoolName "TestPool" -SystemInfo $mockSystemInfo
```

### 3. **Flexibility**
- Functions can work with different data sources
- No coupling to specific global variable names
- Easy to extend with new data structures

### 4. **Maintainability**
- Clear function signatures show dependencies
- Changes to global state don't affect function behavior
- Functions are self-contained

## Migration Guide

### For Existing Functions

1. **Identify Global Dependencies**
   ```powershell
   # Find all global variable usage
   $global:SystemInfo
   $global:DetectionResults
   $global:ESSConfig
   ```

2. **Add Parameters**
   ```powershell
   # Before
   function MyFunction {
       param([string]$Param1)
       $data = $global:SystemInfo
   }
   
   # After
   function MyFunction {
       param(
           [string]$Param1,
           [hashtable]$SystemInfo = $null
       )
       $data = $SystemInfo
   }
   ```

3. **Update Function Calls**
   ```powershell
   # Before
   MyFunction -Param1 "value"
   
   # After
   MyFunction -Param1 "value" -SystemInfo $systemInfo
   ```

### For New Functions

1. **Design with Dependencies in Mind**
   ```powershell
   function New-ModuleFunction {
       param(
           [hashtable]$SystemInfo,
           [hashtable]$Configuration = $null,
           [string]$RequiredParam
       )
       
       # Validate inputs
       if (-not $SystemInfo) {
           throw "SystemInfo is required"
       }
       
       # Use injected dependencies
       $result = Process-Data -Input $SystemInfo -Config $Configuration
       return $result
   }
   ```

2. **Provide Default Values**
   ```powershell
   function Get-EnhancedData {
       param(
           [hashtable]$SystemInfo = $null,
           [hashtable]$DetectionResults = $null
       )
       
       # Use provided data or fall back to managers
       if (-not $SystemInfo) {
           $manager = Get-SystemInformationManager
           $SystemInfo = $manager.SystemInfo
       }
       
       return Process-EnhancedData -SystemInfo $SystemInfo -DetectionResults $DetectionResults
   }
   ```

## Best Practices

### 1. **Parameter Validation**
```powershell
function Process-SystemData {
    param([hashtable]$SystemInfo)
    
    if (-not $SystemInfo -or $SystemInfo.Count -eq 0) {
        throw "SystemInfo parameter is required and cannot be empty"
    }
    
    # Process data...
}
```

### 2. **Optional Parameters**
```powershell
function Get-EnhancedInfo {
    param(
        [hashtable]$SystemInfo,
        [hashtable]$DetectionResults = $null,
        [hashtable]$Configuration = $null
    )
    
    # Function works with or without optional parameters
}
```

### 3. **Manager Classes**
```powershell
class DataManager {
    [hashtable]$Data
    
    [object]GetData([string]$Key) {
        return $this.Data[$Key]
    }
    
    [void]SetData([string]$Key, [object]$Value) {
        $this.Data[$Key] = $Value
    }
}
```

### 4. **Error Handling**
```powershell
function Process-Data {
    param([hashtable]$InputData)
    
    try {
        if (-not $InputData) {
            throw "InputData is required"
        }
        
        # Process data...
        return $result
    }
    catch {
        Write-Error "Failed to process data: $_"
        throw
    }
}
```

## Testing Examples

### Unit Testing
```powershell
Describe "Get-AppPoolIdentity" {
    It "Should return correct identity for valid app pool" {
        $mockSystemInfo = @{
            IIS = @{
                ApplicationPools = @(
                    @{
                        Name = "TestPool"
                        ProcessModel = @{
                            IdentityType = "ApplicationPoolIdentity"
                            UserName = $null
                        }
                    }
                )
            }
        }
        
        $result = Get-AppPoolIdentity -AppPoolName "TestPool" -SystemInfo $mockSystemInfo
        $result | Should Be "ApplicationPoolIdentity"
    }
    
    It "Should return Unknown for missing app pool" {
        $mockSystemInfo = @{
            IIS = @{
                ApplicationPools = @()
            }
        }
        
        $result = Get-AppPoolIdentity -AppPoolName "MissingPool" -SystemInfo $mockSystemInfo
        $result | Should Be "Unknown"
    }
}
```

### Integration Testing
```powershell
Describe "System Information Flow" {
    It "Should process system information through call stack" {
        # Collect system information
        $systemInfo = Get-SystemInformation
        
        # Use in detection
        $detectionResults = Get-ESSWFEDetection -SystemInfo $systemInfo
        
        # Use in summary
        { Show-SystemInfoSummary -SystemInfo $systemInfo -DetectionResults $detectionResults } | Should Not Throw
        
        # Verify data flow
        $systemInfo.ComputerName | Should Not BeNullOrEmpty
        $detectionResults.DeploymentType | Should Not BeNullOrEmpty
    }
}
```

## Conclusion

The refactored module functions now follow proper call stack principles:

- ✅ **No Global Dependencies**: Functions receive data through parameters
- ✅ **Explicit Dependencies**: Function signatures show what data is needed
- ✅ **Loose Coupling**: Functions are not tied to specific global variables
- ✅ **Testable**: Functions can be tested with mock data
- ✅ **Maintainable**: Clear data flow and function responsibilities

This architecture makes the code more robust, testable, and maintainable while following established software engineering principles.
