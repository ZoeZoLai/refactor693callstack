# ESS Interactive Health Checker

## Overview

The ESS Interactive Health Checker provides two modes of operation for ESS Pre-Upgrade Health Checks:

1. **Automated Checker** - Runs complete automated health check process (original functionality)
2. **Interactive Checker** - Allows selective instance checking with user input

## Interactive Mode Features

### 1. Mode Selection
When you run the interactive launcher, you'll be prompted to choose between:
- **Automated Checker**: Checks all detected ESS/WFE instances automatically
- **Interactive Checker**: Allows you to select specific instances to check

### 2. Instance Selection
The interactive mode displays all detected ESS and WFE instances with high-level details:
- **Site Name**: IIS site name
- **Application Path**: Path within the site
- **Database Information**: Database server and name
- **Tenant ID**: Tenant identifier (if available)

You can select instances by:
- Entering comma-separated numbers (e.g., `1,3,5`)
- Entering `all` to select all instances

### 3. ESS URL Configuration
For ESS instances, you can provide a custom ESS URL for API health checks:
- Examples:
  - `http://localhost/Self-Service/NZ_ESS`
  - `https://ess.company.com/Self-Service/NZ_ESS`
  - `http://server01:8080/ESS`

### 4. Selective Validation
The interactive mode performs validation checks only on:
- Selected ESS instances (ESS-specific validations)
- Selected WFE instances (WFE-specific validations)
- System requirements (always performed)
- ESS API health checks (if URL provided)

### 5. Targeted Reports
Generates focused HTML reports containing:
- System information
- Selected instances details
- ESS URL used for API checks
- Health check results for selected instances only

## Usage

### Running the Interactive Checker

```powershell
# Run the interactive launcher
.\RunInteractiveHealthCheck.ps1
```

### Example Interactive Session

```
ESS Pre-Upgrade Health Checker - Interactive Mode
=================================================

Please select the health check mode:

1. Automated Checker
   - Runs complete automated health check process
   - Checks all detected ESS/WFE instances automatically
   - Generates comprehensive report for all instances

2. Interactive Checker
   - Allows selective instance checking
   - Prompts for ESS URL input for API health checks
   - Generates targeted report for selected instances only

Enter your choice (1 or 2): 2

Starting interactive health checks...
Step 1: Collecting system information...
Step 2: Detecting ESS/WFE installations...

=== Available ESS and WFE Instances ===

ESS Instances:
  1. ESS Instance
     Site: Default Web Site
     Path: /Self-Service/NZ_ESS
     Database: SQLSERVER01/PayGlobalDB
     Tenant ID: NZ001

WFE Instances:
  2. WFE Instance
     Site: Default Web Site
     Path: /WorkflowEngine
     Database: SQLSERVER01/WorkflowDB
     Tenant ID: NZ001

Please select the instances you would like to check:
Enter instance numbers separated by commas (e.g., 1,3,5)
Or enter 'all' to select all instances

Your selection: 1

Selected instances:
  ESS Instances: 1
  WFE Instances: 0

ESS URL Configuration for API Health Checks
===========================================

For ESS API health checks, please provide the ESS URL.
This should be the base URL where the ESS application is accessible.

Examples:
  - http://localhost/Self-Service/NZ_ESS
  - https://ess.company.com/Self-Service/NZ_ESS
  - http://server01:8080/ESS

Enter ESS URL (or press Enter to skip): http://localhost/Self-Service/NZ_ESS

ESS URL accepted: http://localhost/Self-Service/NZ_ESS

Step 5: Running selective validation checks...
Step 6: Generating targeted health check report...

=== Interactive Health Check Summary ===
System Information:
  Computer Name: SERVER01
  OS Version: Microsoft Windows Server 2019 Standard
  IIS Installed: True

Selected Instances:
  ESS Instances: 1
  WFE Instances: 0
  ESS URL for API: http://localhost/Self-Service/NZ_ESS

Health Check Results:
  Total Checks: 15
  Passed: 12
  Failed: 2
  Warnings: 1
  Info: 0
=========================================

Interactive Health Checks completed successfully!
Report generated at: C:\MAC\refactor693callstack\Reports\ESS_Interactive_HealthCheck_Report_20250109_143022.html
```

## File Structure

```
├── RunInteractiveHealthCheck.ps1          # Interactive launcher script
├── RunHealthCheck.ps1                     # Original automated launcher
├── src/
│   ├── Main.ps1                          # Updated with interactive functions
│   ├── Interactive/
│   │   └── InteractiveHealthCheck.ps1    # Interactive functionality
│   ├── Core/
│   │   └── ReportGenerator.ps1           # Updated with targeted reports
│   └── ... (other existing modules)
└── Reports/                              # Generated reports
    ├── ESS_HealthCheck_Report_*.html     # Automated reports
    └── ESS_Interactive_HealthCheck_Report_*.html  # Interactive reports
```

## Benefits of Interactive Mode

1. **Faster Execution**: Only checks selected instances
2. **Focused Results**: Reports contain only relevant information
3. **Custom URLs**: Use different ESS URLs for API health checks
4. **Selective Testing**: Test specific instances during development/debugging
5. **Reduced Noise**: Avoid checking instances you don't need to validate

## Call Stack Principles

The interactive functionality follows the same call stack principles as the original tool:

- **Dependency Injection**: All manager instances are passed as parameters
- **No Global Variables**: All state is managed through passed objects
- **Modular Design**: Interactive functionality is in separate modules
- **Composable Functions**: Each function has a single responsibility
- **Testable Components**: Each component can be tested independently

## Error Handling

The interactive mode includes comprehensive error handling:
- Invalid instance selections are rejected with clear messages
- Invalid URLs are validated before use
- Graceful handling of missing instances or modules
- Clear error messages for troubleshooting

## Compatibility

The interactive mode is fully compatible with the existing automated mode:
- Uses the same underlying validation functions
- Generates reports in the same format
- Maintains all existing functionality
- Can be used alongside the original automated checker
