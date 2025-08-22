# ESS Health Checker - Call Stack Architecture

## Overview

The ESS Health Checker has been refactored to follow proper call stack principles, ensuring clear separation of concerns, proper dependency management, and maintainable code structure.

## Call Stack Principles Applied

### 1. **Dependency Injection**
- Components receive their dependencies through parameters rather than accessing global state
- Configuration is injected into components that need it
- Reduces tight coupling between modules

### 2. **Single Responsibility Principle**
- Each module has a single, well-defined responsibility
- Clear boundaries between different layers of the application
- Functions are focused and do one thing well

### 3. **Dependency Order Management**
- Modules are loaded in the correct dependency order
- Clear hierarchy of dependencies prevents circular references
- Explicit dependency declaration and validation

### 4. **State Management**
- Centralized state management through dedicated managers
- Reduced reliance on global variables
- Proper encapsulation of state

## Architecture Layers

### Layer 1: Core Infrastructure
**Location**: `src/Core/`
**Purpose**: Foundation components that have no dependencies

#### Components:
- **ModuleLoader.ps1**: Manages module loading order and dependency validation
- **HealthCheckCore.ps1**: Core health check result management with classes
- **Config.ps1**: Configuration management with dependency injection
- **ReportGenerator.ps1**: Report generation with injected dependencies
- **HealthCheckOrchestrator.ps1**: Main orchestrator coordinating the entire process

### Layer 2: System Information
**Location**: `src/modules/System/`
**Purpose**: Collects and manages system information

#### Components:
- **HardwareInfo.ps1**: Hardware information collection
- **OSInfo.ps1**: Operating system information
- **IISInfo.ps1**: IIS configuration and status
- **SQLInfo.ps1**: SQL Server information
- **SystemInfoOrchestrator.ps1**: Coordinates system information collection

### Layer 3: Detection
**Location**: `src/modules/Detection/`
**Purpose**: Detects ESS and WFE installations

#### Components:
- **ESSDetection.ps1**: ESS installation detection
- **WFEDetection.ps1**: WFE installation detection
- **ESSHealthCheckAPI.ps1**: API health check functionality
- **DetectionOrchestrator.ps1**: Coordinates detection processes

### Layer 4: Utilities
**Location**: `src/modules/Utils/`
**Purpose**: Shared utility functions

#### Components:
- **HelperFunctions.ps1**: Common utility functions used across the application

### Layer 5: Validation
**Location**: `src/modules/Validation/`
**Purpose**: Performs health check validations

#### Components:
- **SystemRequirements.ps1**: System requirement validation
- **InfrastructureValidation.ps1**: Infrastructure validation
- **ESSValidation.ps1**: ESS-specific validation
- **ValidationOrchestrator.ps1**: Coordinates validation processes

## Call Stack Flow

```
RunHealthCheck.ps1 (Entry Point)
    ↓
Main.ps1 (Application Initialization)
    ↓
ModuleLoader.ps1 (Load Dependencies)
    ↓
HealthCheckOrchestrator.ps1 (Main Orchestrator)
    ↓
1. CollectSystemInformation()
   - SystemInfoOrchestrator.ps1
   - HardwareInfo.ps1, OSInfo.ps1, IISInfo.ps1, SQLInfo.ps1
    ↓
2. DetectESSWFEDeployment()
   - DetectionOrchestrator.ps1
   - ESSDetection.ps1, WFEDetection.ps1, ESSHealthCheckAPI.ps1
    ↓
3. RunValidationChecks()
   - ValidationOrchestrator.ps1
   - SystemRequirements.ps1, InfrastructureValidation.ps1, ESSValidation.ps1
    ↓
4. GenerateReport()
   - ReportGenerator.ps1
```

## Key Improvements

### 1. **Clear Entry Points**
- Single entry point through `RunHealthCheck.ps1`
- Clear initialization flow in `Main.ps1`
- Proper module loading sequence

### 2. **Dependency Management**
- Explicit dependency declaration in `ModuleLoader.ps1`
- Validation of required functions and modules
- Clear loading order prevents circular dependencies

### 3. **State Management**
- `HealthCheckManager` class for result management
- `ESSConfiguration` class for configuration management
- Reduced global variable usage

### 4. **Error Handling**
- Proper error propagation through the call stack
- Clear error messages with context
- Graceful degradation when possible

### 5. **Testability**
- Components can be tested in isolation
- Dependencies can be mocked or injected
- Clear interfaces between components

## Usage Examples

### Basic Usage
```powershell
# Run the health checker
.\RunHealthCheck.ps1
```

### Programmatic Usage
```powershell
# Import and use programmatically
. .\src\Main.ps1
$reportPath = Start-ESSHealthChecks
```

### Testing Dependencies
```powershell
# Test that all dependencies are available
Test-HealthCheckDependencies
```

## Migration Guide

### From Old Structure
1. **Global Variables**: Replace `$global:HealthCheckResults` with `Get-HealthCheckResults()`
2. **Configuration**: Replace `$global:ESSConfig` with `Get-ESSConfiguration()`
3. **Module Imports**: Use `Load-Modules()` instead of manual imports
4. **Error Handling**: Use proper try-catch blocks with error propagation

### Benefits
- **Maintainability**: Clear structure makes code easier to maintain
- **Testability**: Components can be tested independently
- **Scalability**: Easy to add new modules following the same pattern
- **Debugging**: Clear call stack makes debugging easier
- **Documentation**: Self-documenting code structure

## Best Practices

### 1. **Module Development**
- Follow the established layer structure
- Declare dependencies explicitly
- Use dependency injection for configuration
- Implement proper error handling

### 2. **Function Design**
- Single responsibility principle
- Clear input/output contracts
- Proper parameter validation
- Meaningful error messages

### 3. **State Management**
- Use managers for state management
- Avoid global variables
- Proper encapsulation
- Thread-safe operations

### 4. **Error Handling**
- Propagate errors up the call stack
- Provide context in error messages
- Use appropriate error types
- Log errors for debugging

## Future Enhancements

### 1. **Plugin Architecture**
- Support for custom validation modules
- Dynamic module loading
- Configuration-driven validation rules

### 2. **Performance Optimization**
- Parallel execution where possible
- Caching of system information
- Lazy loading of modules

### 3. **Enhanced Reporting**
- Multiple report formats
- Customizable report templates
- Real-time progress reporting

### 4. **Configuration Management**
- External configuration files
- Environment-specific settings
- Configuration validation

## Conclusion

The refactored architecture follows call stack principles to create a maintainable, testable, and scalable health checker application. The clear separation of concerns and proper dependency management make the code easier to understand, modify, and extend.
