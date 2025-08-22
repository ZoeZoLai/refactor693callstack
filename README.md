# ESS Pre-Upgrade Health Checker

A comprehensive PowerShell-based health check system for ESS (Employee Self-Service) pre-upgrade validation, designed following **Call Stack Principles** for maintainability, testability, and clear dependency management.

## 🎯 Overview

This tool performs comprehensive health checks on ESS and WFE (Web Front End) deployments to ensure system readiness for upgrades. It validates system requirements, detects installations, checks connectivity, and generates detailed reports.

## 🏗️ Architecture - Call Stack Principles

### Core Design Philosophy

The project follows **Call Stack Principles** to eliminate global state dependencies and ensure clear data flow:

- **No Global Variables**: All data is passed explicitly through parameters
- **Dependency Injection**: Functions receive required data as parameters
- **Single Responsibility**: Each module has a clear, focused purpose
- **Testable Components**: Functions can be tested in isolation
- **Clear Data Flow**: Explicit parameter passing shows dependencies

### Project Structure

```
refactor693callstack/
├── RunHealthCheck.ps1              # Main launcher script
├── src/
│   ├── Main.ps1                    # Application entry point
│   ├── Core/
│   │   ├── Config.ps1              # Configuration management
│   │   ├── HealthCheckCore.ps1     # Core health check functions
│   │   ├── HealthCheckOrchestrator.ps1  # Main orchestrator class
│   │   └── ReportGenerator.ps1     # HTML report generation
│   ├── modules/
│   │   ├── System/                 # System information collection
│   │   │   ├── SystemInfoOrchestrator.ps1
│   │   │   ├── HardwareInfo.ps1
│   │   │   ├── OSInfo.ps1
│   │   │   ├── IISInfo.ps1
│   │   │   └── SQLInfo.ps1
│   │   ├── Detection/              # ESS/WFE detection
│   │   │   ├── DetectionOrchestrator.ps1
│   │   │   ├── ESSDetection.ps1
│   │   │   ├── WFEDetection.ps1
│   │   │   └── ESSHealthCheckAPI.ps1
│   │   ├── Validation/             # System validation
│   │   │   ├── ValidationOrchestrator.ps1
│   │   │   ├── SystemRequirements.ps1
│   │   │   ├── InfrastructureValidation.ps1
│   │   │   └── ESSValidation.ps1
│   │   └── Utils/                  # Utility functions
│   │       └── HelperFunctions.ps1
│   └── tests/                      # Test files
└── README.md                       # This file
```

## 🚀 Quick Start

### Prerequisites

- **PowerShell 5.1+** or **PowerShell Core 6.0+**
- **Windows Server** with IIS installed
- **Administrator privileges** (required for system checks)
- **ESS/WFE deployment** to validate

### Running the Health Check

1. **Clone or download** the project to your system
2. **Open PowerShell as Administrator**
3. **Navigate** to the project directory
4. **Run** the health check:

```powershell
.\RunHealthCheck.ps1
```

### Expected Output

```
ESS Pre-Upgrade Health Checker
================================
Loading ESS Health Checker modules...
Initializing ESS Health Checker...
Starting health checks...
Starting ESS Pre-Upgrade Health Checks...

Step 1: Collecting system information...
Step 2: Detecting ESS/WFE deployment...
Step 3: Running validation checks...
Step 4: Generating health check report...

=== Health Check Summary ===
System Information:
  Computer Name: SERVER01
  OS Version: Windows Server 2019
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

Health Checks completed successfully!
Report generated at: C:\Reports\ESS_HealthCheck_Report_20241201_143022.html
```

## 🔧 Call Stack Implementation

### Execution Flow

```
RunHealthCheck.ps1
└── Main.ps1 (Start-ESSHealthChecks)
    └── HealthCheckOrchestrator
        ├── Initialize()
        ├── CollectSystemInformation()
        │   └── SystemInformationManager
        │       ├── Get-OSInformation()
        │       ├── Get-HardwareInformation()
        │       ├── Get-NetworkInformation()
        │       ├── Get-IISInformation()
        │       └── Get-SQLServerInformation()
        ├── DetectESSWFEDeployment()
        │   └── DetectionManager
        │       ├── Test-IISInstallation()
        │       ├── Find-ESSInstances()
        │       └── Find-WFEInstances()
        ├── RunValidationChecks()
        │   └── ValidationManager
        │       ├── Test-SystemRequirements()
        │       ├── Test-IISConfiguration()
        │       ├── Test-NetworkConnectivity()
        │       ├── Test-SecurityPermissions()
        │       ├── Test-ESSWFEDetection()
        │       ├── Test-DatabaseConnectivity()
        │       ├── Test-WebConfigEncryptionValidation()
        │       ├── Test-ESSVersionValidation()
        │       ├── Test-ESSHTTPSValidation()
        │       └── Test-ESSAPIHealthCheckValidation()
        ├── GenerateReport()
        │   └── New-HealthCheckReport()
        └── DisplaySummary()
```

### Key Classes

#### HealthCheckOrchestrator
- **Purpose**: Main coordinator for the entire health check process
- **Responsibilities**: 
  - Manages execution flow
  - Coordinates between different managers
  - Handles error propagation
  - Maintains state for the health check session

#### SystemInformationManager
- **Purpose**: Collects comprehensive system information
- **Data Collected**:
  - Operating system details
  - Hardware specifications
  - Network configuration
  - IIS installation and configuration
  - SQL Server information
  - Registry settings

#### DetectionManager
- **Purpose**: Detects ESS and WFE installations
- **Capabilities**:
  - IIS installation validation
  - ESS instance discovery
  - WFE instance discovery
  - Deployment type determination

#### ValidationManager
- **Purpose**: Performs comprehensive system validation
- **Validation Categories**:
  - System requirements (CPU, memory, disk space)
  - IIS configuration
  - Network connectivity
  - Security permissions
  - Database connectivity
  - ESS version compatibility
  - API health checks

## 📊 Health Check Categories

### 1. System Requirements
- **CPU**: Minimum 2 GHz, 4+ cores
- **Memory**: Minimum 32 GB RAM
- **Disk Space**: Minimum 10 GB free space
- **Operating System**: Windows Server 2012 R2+
- **IIS**: Version 7.5+
- **.NET Framework**: Version 4.8+

### 2. ESS/WFE Detection
- **ESS Installations**: Locates and validates ESS instances
- **WFE Installations**: Identifies Web Front End components
- **Deployment Types**: Standalone, Combined, or Distributed

### 3. Infrastructure Validation
- **IIS Configuration**: Site and application pool validation
- **Network Connectivity**: Internet and local network access
- **Security Permissions**: Administrator rights verification
- **File System Access**: Read/write permissions validation

### 4. ESS-Specific Validation
- **Database Connectivity**: SQL Server connection tests
- **Web.Config Encryption**: Authentication encryption validation
- **Version Compatibility**: ESS and PayGlobal version checks
- **HTTPS Usage**: Security protocol validation
- **API Health**: ESS API endpoint health checks

## 📋 Configuration

### Default Configuration
The system uses built-in default values for:
- **Report Output Path**: `./Reports/`
- **Report Name Format**: `ESS_HealthCheck_Report_{timestamp}.html`
- **API Timeouts**: 30 seconds
- **Retry Attempts**: 3

### Custom Configuration
To customize settings, modify `src/Core/Config.ps1`:

```powershell
# Example configuration customization
$ESSConfig = @{
    ReportSettings = @{
        ReportOutputPath = "C:\CustomReports\"
        ReportNameFormat = "Custom_ESS_Report_{0:yyyyMMdd}.html"
    }
    APIHealthCheck = @{
        ConnectionTimeoutSeconds = 60
        ReadWriteTimeoutSeconds = 120
        MaxRetries = 5
    }
}
```

## 🧪 Testing

### Running Tests
```powershell
# Run all tests
.\src\tests\Test-HealthCheck.ps1

# Run specific test categories
.\src\tests\Test-SystemValidation.ps1
.\src\tests\Test-ESSDetection.ps1
```

### Test Coverage
- **Unit Tests**: Individual function testing
- **Integration Tests**: Module interaction testing
- **End-to-End Tests**: Complete workflow validation

## 🔍 Troubleshooting

### Common Issues

#### 1. "Access Denied" Errors
**Solution**: Run PowerShell as Administrator

#### 2. "Module Not Found" Errors
**Solution**: Ensure all files are in the correct directory structure

#### 3. "IIS Not Installed" Warnings
**Solution**: Install IIS and required features

#### 4. "Database Connection Failed"
**Solution**: Verify SQL Server is running and accessible

#### 5. "ESS API Health Check Failed"
**Solution**: Check ESS service status and network connectivity

### Debug Mode
Enable verbose logging:
```powershell
$VerbosePreference = "Continue"
.\RunHealthCheck.ps1
```

### Log Files
Check the generated HTML report for detailed results and recommendations.

## 📈 Performance

### Typical Execution Time
- **System Information Collection**: 5-10 seconds
- **ESS/WFE Detection**: 10-15 seconds
- **Validation Checks**: 30-60 seconds
- **Report Generation**: 5-10 seconds
- **Total**: 1-2 minutes

### Resource Usage
- **Memory**: ~50-100 MB
- **CPU**: Low impact
- **Disk**: Minimal (report generation only)

## 🤝 Contributing

### Development Guidelines
1. **Follow Call Stack Principles**: No global variables, explicit parameter passing
2. **Single Responsibility**: Each function/module has one clear purpose
3. **Error Handling**: Proper try-catch blocks with meaningful error messages
4. **Documentation**: Comment all functions with proper PowerShell help
5. **Testing**: Write tests for new functionality

### Code Style
- Use **PascalCase** for function names
- Use **camelCase** for variables
- Include **comment-based help** for all functions
- Follow **PowerShell best practices**

## 📄 License

This project is developed for internal use. Please refer to your organization's software usage policies.

## 📞 Support

For technical support or questions:
- **Documentation**: Check the generated HTML reports for detailed information
- **Logs**: Review PowerShell output for error details
- **Configuration**: Verify settings in `src/Core/Config.ps1`

---

**Version**: 2.0  
**Last Updated**: December 2024  
**Compatibility**: ESS 5.4+, Windows Server 2012 R2+
