# ESS Pre-Upgrade Health Checker

A comprehensive PowerShell-based health checking tool for MYOB PayGlobal ESS (Employee Self Service) systems before upgrade operations.

## 🎯 Overview

The ESS Pre-Upgrade Health Checker is designed to validate system readiness for ESS upgrades by performing comprehensive checks on:

- **System Requirements**: Hardware, OS, .NET Framework, IIS
- **ESS/WFE Detection**: Automatic discovery of ESS and WFE installations
- **Database Connectivity**: SQL Server connections and database validation
- **API Health Checks**: ESS API endpoint validation
- **Configuration Validation**: Web.config encryption, authentication modes
- **Version Compatibility**: ESS and PayGlobal version compatibility checks

## 🏗️ Architecture

The project follows **Call Stack Principles** with clean dependency injection, single responsibility design, and clear separation of concerns. **All global variables have been eliminated** in favor of explicit parameter passing through the call stack.

### 🎯 **Architecture Overview**

The health checker follows a **3-phase approach**:

1. **🔍 Discovery Phase** (`Detection/`): Finds ESS/WFE installations and API endpoints
2. **📊 Information Phase** (`SystemInfo/`): Collects detailed system information  
3. **✅ Validation Phase** (`Validation/`): Validates discovered components against requirements

This separation ensures each phase can be tested independently and makes the codebase highly maintainable.

```
refactor693callstack/
├── Reports/                # Generated HTML reports (user-accessible)
├── src/                    # Source code (developers only)
│   ├── Core/              # Foundation components
│   │   ├── Config.ps1     # Configuration management
│   │   ├── HealthCheckCore.ps1 # Result management & core utilities
│   │   └── ReportGenerator.ps1 # HTML report generation
│   ├── Detection/         # Discovery modules
│   │   ├── ESSDetection.ps1 # ESS installation detection
│   │   ├── WFEDetection.ps1 # WFE installation detection
│   │   ├── ESSHealthCheckAPI.ps1 # API health check functions
│   │   └── DetectionOrchestrator.ps1 # Detection coordination
│   ├── Interactive/       # Interactive mode modules
│   │   └── InteractiveHealthCheck.ps1 # Interactive health check functionality
│   ├── SystemInfo/        # System information collection
│   │   ├── OSInfo.ps1     # Operating system information
│   │   ├── HardwareInfo.ps1 # Hardware & network information
│   │   ├── IISInfo.ps1    # IIS configuration
│   │   ├── SQLInfo.ps1    # SQL Server information
│   │   └── SystemInfoOrchestrator.ps1 # System info collection coordination
│   ├── Validation/        # Validation modules
│   │   ├── SystemRequirements.ps1 # System requirement validation
│   │   ├── InfrastructureValidation.ps1 # Infrastructure validation
│   │   ├── ESSValidation.ps1 # ESS-specific validation
│   │   ├── ValidationOrchestrator.ps1 # Validation coordination
│   │   └── SystemValidation.ps1 # Validation wrapper
│   ├── Utils/             # Utility functions
│   │   └── HelperFunctions.ps1 # Common helper functions
│   ├── Main.ps1           # Main orchestration script
│   └── tests/             # Test files
├── RunHealthCheck.ps1     # Legacy automated launcher script
├── RunInteractiveHealthCheck.ps1 # New interactive launcher script
├── README.md              # This documentation
└── .gitignore             # Git ignore rules
```

## 🚀 Features

### ✅ **Dual Operation Modes**
- **Automated Mode**: Complete system-wide health check of all detected instances
- **Interactive Mode**: Selective health check of user-chosen instances with custom ESS URL

### ✅ System Requirements Validation
- **Hardware**: Memory, CPU cores, processor speed, disk space
- **Operating System**: Windows Server compatibility
- **Software**: .NET Framework, IIS installation and configuration
- **Network**: Connectivity and adapter validation

### ✅ ESS/WFE Detection
- **Automatic Discovery**: Finds all ESS and WFE installations
- **Configuration Parsing**: Reads payglobal.config and tenants.config
- **Version Detection**: Extracts ESS and PayGlobal versions
- **Database Connection**: Validates database connectivity
- **Interactive Selection**: User can choose specific instances to check

### ✅ API Health Checks
- **Endpoint Validation**: Tests ESS API endpoints
- **Component Status**: Checks PayGlobal Database, SelfService Software, Bridge
- **Response Parsing**: Handles JSON/XML health check responses
- **Error Handling**: Comprehensive error reporting
- **Custom URL Support**: Interactive mode allows custom ESS URL input

### ✅ Configuration Validation
- **Web.config Encryption**: Validates encryption for SingleSignOn
- **Authentication Modes**: Checks PayGlobal vs AlternativeUsername
- **Database Connections**: Validates connection strings
- **SSL Certificates**: HTTPS configuration validation

### ✅ Report Generation
- **HTML Reports**: Comprehensive, styled HTML reports
- **Executive Summary**: High-level status overview
- **Detailed Results**: Per-check results with explanations
- **Recommendations**: Actionable upgrade guidance
- **Targeted Reports**: Interactive mode generates reports for selected instances only

## 📋 Prerequisites

- **PowerShell 5.1+** or **PowerShell Core 6+**
- **Windows Server 2016+** or **Windows 10+**
- **Administrator privileges** (for IIS and system information access)
- **IIS Management Tools** (for IIS configuration access)
- **SQL Server Management Tools** (for database connectivity)

## 🛠️ Installation

1. **Clone or Download** the project to your local machine
2. **Navigate** to the project directory
3. **Run as Administrator** for full functionality

```powershell
# Navigate to project directory
cd C:\path\to\refactor693callstack

# Run the health checker
.\RunHealthCheck.ps1
```

## 📖 Usage

### **Interactive Mode (Recommended)**

The new interactive health checker provides a user-friendly menu to choose between automated and interactive modes:

```powershell
# Launch interactive health checker
.\RunInteractiveHealthCheck.ps1
```

**Interactive Mode Features:**
- **Mode Selection**: Choose between automated or interactive health checking
- **Instance Selection**: View all detected ESS/WFE instances with details (site, type, alias)
- **Selective Checking**: Choose specific instances to validate (comma-separated numbers)
- **Custom ESS URL**: Input custom ESS URL for API health checks
- **Targeted Reports**: Generate reports only for selected instances

### **Interactive Mode Workflow**

1. **Launch**: Run `.\RunInteractiveHealthCheck.ps1`
2. **Mode Selection**: Choose between automated (1) or interactive (2) mode
3. **System Discovery**: Tool automatically collects system info and detects all ESS/WFE instances
4. **Instance Display**: View all detected instances with:
   - Site name
   - Instance type (ESS or WFE)
   - Instance alias
   - Installation path
5. **Instance Selection**: Choose which instances to check:
   - Enter ESS instance numbers (e.g., `1,3` for instances 1 and 3)
   - Enter WFE instance numbers (e.g., `2` for instance 2)
   - Leave empty to skip that instance type
6. **ESS URL Input**: Provide custom ESS URL for API health checks
7. **Selective Validation**: Tool performs health checks only on selected instances
8. **Targeted Report**: Generate HTML report with results for selected instances only

### **Automated Mode (Legacy)**

```powershell
# Run complete automated health check
.\RunHealthCheck.ps1

# Run with verbose output
.\RunHealthCheck.ps1 -Verbose
```

### Advanced Usage

```powershell
# Load modules manually for testing
. .\src\Main.ps1

# Run individual components with explicit manager instances
$healthCheckManager = [HealthCheckResultManager]::new()
$detectionManager = [DetectionManager]::new()
$validationManager = [ValidationManager]::new()
$systemInfoManager = [SystemInformationManager]::new()

$systemInfo = Get-SystemInformation -SystemInfoManager $systemInfoManager
$detectionResults = Get-ESSWFEDetection -SystemInfo $systemInfo -Manager $healthCheckManager -DetectionManager $detectionManager
Start-SystemValidation -SystemInfo $systemInfo -DetectionResults $detectionResults -Manager $healthCheckManager -ValidationManager $validationManager
```

## 📊 Output

### Console Output
- **Real-time Progress**: Step-by-step execution status
- **Color-coded Results**: PASS (Green), FAIL (Red), WARNING (Yellow), INFO (Blue)
- **Summary Statistics**: Total checks, passed, failed, warnings

### HTML Report
- **Location**: Generated in the `Reports/` folder at project root
- **Executive Summary**: High-level system status
- **Detailed Results**: Per-check results with explanations
- **System Information**: Hardware, OS, IIS, SQL Server details
- **ESS/WFE Instances**: Detected installations with configuration
- **Recommendations**: Actionable upgrade guidance
- **Interactive Reports**: Targeted reports for selected instances only (interactive mode)

## 🔧 Configuration

The health checker uses a configuration system with sensible defaults:

```powershell
# Create custom configuration
$config = New-ESSConfiguration

# Modify settings
$config.MinimumRequirements.MinimumMemoryGB = 16
$config.APIHealthCheck.DefaultTimeoutSeconds = 120

# Use custom configuration
Get-ESSConfiguration -Configuration $config
```

## 🧪 Testing

The project includes comprehensive test files:

```powershell

# Simple functionality test
. .\src\tests\SimpleTest.ps1
```

## 🏛️ Call Stack Principles

This project follows strict call stack principles with a clean, modular architecture:

### ✅ Separation of Concerns
- **Detection/**: Discovers what ESS/WFE installations exist
- **SystemInfo/**: Collects detailed system information
- **Validation/**: Validates discovered components against requirements
- **Core/**: Provides foundation services and utilities

### ✅ Dependency Injection
- **Zero Global Variables**: All global state has been eliminated
- **Explicit Parameter Passing**: Manager instances passed through call stack
- **No Hidden Dependencies**: All dependencies explicitly declared
- **Clear Input/Output Contracts**: Functions receive data through explicit parameters
- **Independent Testing**: Each module can be tested without global state

### ✅ Single Responsibility
- Each folder has one clear purpose
- Each module focuses on a specific domain
- Functions are focused and do one thing well
- Clear separation between discovery and validation

### ✅ Testability
- Functions can be tested in isolation
- Mock data support for all functions
- No hidden dependencies
- Individual modules can be tested without full system

### ✅ Maintainability
- Clear data flow through function parameters
- Easy to understand and modify
- Consistent patterns throughout
- Logical grouping of related functionality

## 🔄 Refactoring Details (v2.2)

### **Global Variable Elimination**
The codebase has been completely refactored to eliminate all global variables:

**Before (v2.1):**
```powershell
# Global variables (ANTI-PATTERN)
$script:HealthCheckManager = $null
$script:ValidationManager = $null
$script:DetectionManager = $null

function Get-HealthCheckManager {
    if (-not $script:HealthCheckManager) {
        $script:HealthCheckManager = [HealthCheckResultManager]::new()
    }
    return $script:HealthCheckManager
}
```

**After (v2.2):**
```powershell
# Pure dependency injection (CLEAN)
function Start-ESSHealthChecks {
    param()
    
    # Create manager instances at top level
    $healthCheckManager = [HealthCheckResultManager]::new()
    $detectionManager = [DetectionManager]::new()
    $validationManager = [ValidationManager]::new()
    $systemInfoManager = [SystemInformationManager]::new()
    
    # Pass managers through call stack
    $systemInfo = Get-SystemInformation -SystemInfoManager $systemInfoManager
    $detectionResults = Get-ESSWFEDetection -SystemInfo $systemInfo -Manager $healthCheckManager -DetectionManager $detectionManager
    Start-SystemValidation -SystemInfo $systemInfo -DetectionResults $detectionResults -Manager $healthCheckManager -ValidationManager $validationManager
}
```

### **Manager Classes**
Four manager classes handle different aspects of the health check:

- **`HealthCheckResultManager`**: Manages health check results and reporting
- **`DetectionManager`**: Handles ESS/WFE detection logic
- **`ValidationManager`**: Coordinates validation checks
- **`SystemInformationManager`**: Manages system information collection

### **Parameter Passing Pattern**
All functions now follow a consistent parameter passing pattern:

```powershell
function Example-Function {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $true)]
        [object]$Manager,  # HealthCheckResultManager instance
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = $null
    )
    
    # Use manager instance for operations
    $Manager.AddResult($Category, $Check, $Status, $Message)
}
```

## 📝 Example Output

### **Interactive Mode Example**

```
ESS Pre-Upgrade Health Checker - Interactive Mode
=================================================

Choose Health Check Mode:
1. Automated Health Check (check all detected instances)
2. Interactive Health Check (select specific instances)

Enter your choice (1 or 2): 2

=== Interactive Health Check Mode ===

Step 1: Collecting system information...
System information collection completed successfully

Step 2: Detecting ESS/WFE installations...
[PASS] Found 3 ESS installation(s)
[PASS] Found 3 WFE installation(s)

=== Available ESS and WFE Instances ===

ESS Instances:
1. Site: Default Web Site, Alias: ESS, Path: C:\inetpub\wwwroot\ESS
2. Site: ESS-Site, Alias: ESS-Dev, Path: C:\inetpub\wwwroot\ESS-Dev
3. Site: ESS-Site, Alias: ESS-Test, Path: C:\inetpub\wwwroot\ESS-Test

WFE Instances:
1. Site: Default Web Site, Alias: WFE, Path: C:\inetpub\wwwroot\WFE
2. Site: WFE-Site, Alias: WFE-Dev, Path: C:\inetpub\wwwroot\WFE-Dev

Enter ESS instance numbers to check (comma-separated, e.g., 1,3): 1,2
Enter WFE instance numbers to check (comma-separated, e.g., 1,2): 1
Enter ESS URL for API health check: https://ess.company.com/api/v1/healthcheck

Step 3: Running validation checks on selected instances...
[PASS] System Requirements - Memory : Sufficient memory available
[PASS] Database Connectivity - ESS - PG Database Connection : Successfully connected
[PASS] ESS API Health Check - Overall Status : ESS instance is healthy

Step 4: Generating targeted health check report...
Report generated successfully at: C:\path\to\refactor693callstack\Reports\ESS_Interactive_HealthCheck_Report_20250908_215433.html

=== Interactive Health Check Summary ===
Selected Instances:
  ESS Instances Selected: 2
  WFE Instances Selected: 1
  ESS URL: https://ess.company.com/api/v1/healthcheck
Health Check Results:
  Total Checks: 25
  Passed: 23
  Failed: 1
  Warnings: 1
  Info: 0
```

### **Automated Mode Example**

```
ESS Pre-Upgrade Health Checker
===============================

Starting ESS Pre-Upgrade Health Checks...
Step 1: Collecting system information...
  Collecting basic system information...
  Collecting OS information...
  Collecting hardware information...
  Collecting network information...
  Collecting IIS information...
  Collecting registry information...
  Collecting SQL Server information...
System information collection completed successfully

Step 2: Detecting ESS/WFE installations...
[PASS] Found 3 ESS installation(s)
[PASS] Found 3 WFE installation(s)
[PASS] Deployment Type: Combined (ESS + WFE)

Step 3: Running validation checks...
[PASS] System Requirements - Memory : Sufficient memory available
[PASS] System Requirements - CPU Cores : Sufficient CPU cores available
[PASS] Database Connectivity - ESS - PG Database Connection : Successfully connected
[PASS] ESS API Health Check - Overall Status : ESS instance is healthy

Step 4: Generating health check report...
Report generated successfully at: C:\path\to\refactor693callstack\Reports\ESS_HealthCheck_Report_20250906_223306.html

=== Health Check Summary ===
System Information:
  Computer Name: SERVER-NAME
  OS Version: Microsoft Windows Server 2019
  IIS Installed: True
Detection Results:
  ESS Instances: 3
  WFE Instances: 3
  Deployment Type: Combined
Health Check Results:
  Total Checks: 50
  Passed: 44
  Failed: 1
  Warnings: 0
  Info: 5
```

## 🐛 Troubleshooting

### Common Issues

1. **"Insufficient permissions"**
   - Run PowerShell as Administrator
   - Ensure IIS Management Tools are installed

2. **"IIS modules not found"**
   - Install IIS Management Tools
   - Enable IIS Management Console

3. **"Database connection failed"**
   - Verify SQL Server is running
   - Check connection strings in payglobal.config
   - Ensure SQL Server allows remote connections

4. **"ESS API health check failed"**
   - Verify ESS application is running
   - Check IIS application pool status
   - Validate API endpoint URLs

## 🤝 Contributing

1. **Follow Call Stack Principles**: Pass all dependencies as explicit parameters
2. **No Global Variables**: Never use `$script:` or global variables
3. **Dependency Injection**: All manager instances must be passed as parameters
4. **Single Responsibility**: Maintain single responsibility for each module
5. **Comprehensive Error Handling**: Add proper error handling and logging
6. **Parameter Validation**: Validate all input parameters
7. **Type Safety**: Use proper type declarations for parameters

## 📄 License

This project is proprietary software for MYOB PayGlobal ESS systems.

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the generated HTML report for detailed error information
3. Run with `-Verbose` flag for detailed logging
4. Contact the development team

---

**Version**: 2.3 - Interactive Health Checker with Dual Operation Modes  
**Last Updated**: January 2025  
**Author**: Zoe Lai

### 🎉 **Recent Improvements (v2.3)**
- **✅ Interactive Health Checker**: New interactive mode with user-friendly instance selection
- **✅ Dual Operation Modes**: Choose between automated (all instances) or interactive (selected instances)
- **✅ Instance Selection**: View and select specific ESS/WFE instances with detailed information
- **✅ Custom ESS URL Support**: Input custom ESS URL for API health checks in interactive mode
- **✅ Targeted Reports**: Generate reports only for selected instances with accurate wording
- **✅ Enhanced User Experience**: Clear distinction between "found" vs "selected" instances in reports
- **✅ Improved Report Generation**: Reports generated in correct location with proper path resolution

### 🎉 **Previous Improvements (v2.2)**
- **✅ Zero Global Variables**: Completely eliminated all `$script:` global variables
- **✅ Pure Dependency Injection**: All manager instances passed through call stack
- **✅ Enhanced Type Safety**: Proper type declarations for all parameters
- **✅ Improved Error Handling**: Better parameter validation and error messages
- **✅ Cleaner Architecture**: No hidden dependencies or global state
- **✅ Better Testability**: Functions can be tested in complete isolation
- **✅ Maintainable Code**: Clear data flow through explicit parameters

### 🎉 **Previous Improvements (v2.1)**
- **✅ Restructured Architecture**: Separated discovery, information collection, and validation into distinct folders
- **✅ Improved Maintainability**: Clear separation of concerns with single responsibility per folder
- **✅ Enhanced Testability**: Each phase can be tested independently
- **✅ Better Organization**: Logical grouping of related functionality
- **✅ User-Friendly Structure**: Reports folder moved to root level for easy access
- **✅ Clean Source Code**: Source code isolated in `src/` folder, reports accessible at root
- **✅ No Breaking Changes**: All existing functionality preserved
