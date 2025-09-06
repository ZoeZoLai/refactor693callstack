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

The project follows **Call Stack Principles** with clean dependency injection, single responsibility design, and clear separation of concerns:

### 🎯 **Architecture Overview**

The health checker follows a **3-phase approach**:

1. **🔍 Discovery Phase** (`Detection/`): Finds ESS/WFE installations and API endpoints
2. **📊 Information Phase** (`SystemInfo/`): Collects detailed system information  
3. **✅ Validation Phase** (`Validation/`): Validates discovered components against requirements

This separation ensures each phase can be tested independently and makes the codebase highly maintainable.

```
src/
├── Core/                    # Foundation components
│   ├── Config.ps1          # Configuration management
│   ├── HealthCheckCore.ps1 # Result management & core utilities
│   └── ReportGenerator.ps1 # HTML report generation
├── Detection/              # Discovery modules
│   ├── ESSDetection.ps1    # ESS installation detection
│   ├── WFEDetection.ps1    # WFE installation detection
│   ├── ESSHealthCheckAPI.ps1 # API health check functions
│   └── DetectionOrchestrator.ps1 # Detection coordination
├── SystemInfo/             # System information collection
│   ├── OSInfo.ps1          # Operating system information
│   ├── HardwareInfo.ps1    # Hardware & network information
│   ├── IISInfo.ps1         # IIS configuration
│   ├── SQLInfo.ps1         # SQL Server information
│   └── SystemInfoOrchestrator.ps1 # System info collection coordination
├── Validation/             # Validation modules
│   ├── SystemRequirements.ps1 # System requirement validation
│   ├── InfrastructureValidation.ps1 # Infrastructure validation
│   ├── ESSValidation.ps1   # ESS-specific validation
│   ├── ValidationOrchestrator.ps1 # Validation coordination
│   └── SystemValidation.ps1 # Validation wrapper
├── Utils/                  # Utility functions
│   └── HelperFunctions.ps1 # Common helper functions
├── tests/                  # Test files
└── Reports/                # Generated HTML reports
```

## 🚀 Features

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

### ✅ API Health Checks
- **Endpoint Validation**: Tests ESS API endpoints
- **Component Status**: Checks PayGlobal Database, SelfService Software, Bridge
- **Response Parsing**: Handles JSON/XML health check responses
- **Error Handling**: Comprehensive error reporting

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

### Basic Usage

```powershell
# Run complete health check
.\RunHealthCheck.ps1

# Run with verbose output
.\RunHealthCheck.ps1 -Verbose
```

### Advanced Usage

```powershell
# Load modules manually for testing
. .\src\Main.ps1

# Run individual components
$systemInfo = Get-SystemInformation
$detectionResults = Get-ESSWFEDetection -SystemInfo $systemInfo
Start-SystemValidation -SystemInfo $systemInfo -DetectionResults $detectionResults
```

## 📊 Output

### Console Output
- **Real-time Progress**: Step-by-step execution status
- **Color-coded Results**: PASS (Green), FAIL (Red), WARNING (Yellow), INFO (Blue)
- **Summary Statistics**: Total checks, passed, failed, warnings

### HTML Report
- **Executive Summary**: High-level system status
- **Detailed Results**: Per-check results with explanations
- **System Information**: Hardware, OS, IIS, SQL Server details
- **ESS/WFE Instances**: Detected installations with configuration
- **Recommendations**: Actionable upgrade guidance

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
- Functions receive data through explicit parameters
- No global state dependencies
- Clear input/output contracts
- Each module can be tested independently

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

## 📝 Example Output

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
Report generated successfully at: C:\path\to\Reports\ESS_HealthCheck_Report_20250906_223306.html

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

1. Follow the established call stack principles
2. Maintain single responsibility for each module
3. Use dependency injection for all functions
4. Add comprehensive error handling
5. Include verbose logging for debugging

## 📄 License

This project is proprietary software for MYOB PayGlobal ESS systems.

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the generated HTML report for detailed error information
3. Run with `-Verbose` flag for detailed logging
4. Contact the development team

---

**Version**: 2.1 - Clean Architecture with Separation of Concerns  
**Last Updated**: September 2025  
**Author**: Zoe Lai

### 🎉 **Recent Improvements (v2.1)**
- **✅ Restructured Architecture**: Separated discovery, information collection, and validation into distinct folders
- **✅ Improved Maintainability**: Clear separation of concerns with single responsibility per folder
- **✅ Enhanced Testability**: Each phase can be tested independently
- **✅ Better Organization**: Logical grouping of related functionality
- **✅ No Breaking Changes**: All existing functionality preserved
