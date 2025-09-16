# ESS Health Checker - Build Instructions

This directory contains all build-related scripts and outputs for the ESS Health Checker project.

## Directory Structure

```
build/
├── Build-BundledScript.ps1    # Creates single bundled PowerShell script
├── Build-Executable.ps1       # Creates executable from bundled script
├── Install-Requirements.ps1   # Installs build dependencies
├── BUILD.md                   # This documentation file
└── output/                    # Build outputs (git-ignored)
    ├── ESSHealthChecker-Complete.ps1  # Bundled script
    └── ESSHealthChecker.exe           # Final executable
```

## Build Process

### Prerequisites

1. **PowerShell 5.1+** or **PowerShell Core**
2. **Administrator privileges** (for PS2EXE module installation)
3. **Internet connection** (for downloading PS2EXE module)

**Note**: The built executable does NOT require administrator privileges to run, but admin rights are recommended for full functionality (IIS configuration access, registry reads, etc.).

### Quick Build (Recommended)

Run the complete build process in one command:

```powershell
cd build
.\Build-Executable.ps1 -InstallPS2EXE
```

This will:
1. Install PS2EXE module if needed
2. Bundle all source modules into a single script
3. Convert the script to an executable
4. Place outputs in the `output/` folder

### Step-by-Step Build

#### 1. Install Dependencies (First Time Only)

```powershell
cd build
.\Install-Requirements.ps1
```

#### 2. Create Bundled Script

```powershell
.\Build-BundledScript.ps1
```

**Options:**
- `-OutputFile "custom-name.ps1"` - Custom output filename
- `-SourceDirectory "..\src"` - Source directory (default: `..\src`)

#### 3. Create Executable

```powershell
.\Build-Executable.ps1
```

**Options:**
- `-OutputExe "custom-name.exe"` - Custom executable name
- `-BundledScript "input-script.ps1"` - Input bundled script
- `-SkipTest` - Skip syntax validation
- `-InstallPS2EXE` - Install PS2EXE module if missing

## Build Outputs

### ESSHealthChecker-Complete.ps1
- **Purpose**: Single bundled PowerShell script containing all modules
- **Size**: ~200-300 KB
- **Usage**: Can be run directly with PowerShell
- **Dependencies**: None (all modules embedded)

### ESSHealthChecker.exe
- **Purpose**: Standalone executable for distribution
- **Size**: ~15-20 MB
- **Usage**: Right-click to run as administrator, or run from command line
- **Dependencies**: Windows PowerShell (built into Windows)

**Usage:**
- **Right-click** the executable to run as administrator
- **Menu-driven interface** - simply choose 1, 2, or 3
- **No command-line knowledge required**

## Usage Examples

### Building for Development
```powershell
# Quick test build
cd build
.\Build-BundledScript.ps1 -OutputFile "output\test-build.ps1"
```

### Building for Production
```powershell
# Full production build with all checks
cd build
.\Build-Executable.ps1 -InstallPS2EXE
```

### Custom Output Locations
```powershell
# Build to specific locations
.\Build-BundledScript.ps1 -OutputFile "C:\Temp\MyHealthChecker.ps1"
.\Build-Executable.ps1 -OutputExe "C:\Distribution\HealthChecker.exe"
```

## Troubleshooting

### Common Issues

#### PS2EXE Module Installation Fails
```powershell
# Manual installation
Install-Module ps2exe -Force -Scope CurrentUser
```

#### Build Script Path Errors
- Ensure you run scripts from the `build/` directory
- Source directory is automatically set to `..\src` relative to build folder

#### Executable Creation Fails
- Verify bundled script exists and is valid
- Check Windows Defender isn't blocking PS2EXE
- Run PowerShell as Administrator

### Verification

#### Test Bundled Script
```powershell
# Syntax check
.\output\ESSHealthChecker-Complete.ps1 -WhatIf

# Quick functionality test
.\output\ESSHealthChecker-Complete.ps1 -Interactive
```

#### Test Executable
```powershell
# Run executable
.\output\ESSHealthChecker.exe -Interactive
```

## Distribution

### For End Users
- Copy only `build\output\ESSHealthChecker.exe` to target machines
- No additional files or dependencies required
- Requires Windows PowerShell (built into Windows)
- **Administrator privileges recommended** but not required (app will provide helpful warnings)

### For Developers
- Share entire repository for source code access
- Use `git clone` to get complete development environment
- Build outputs are automatically ignored by git

## Build Script Details

### Build-BundledScript.ps1
- **Input**: Source modules from `../src/`
- **Process**: Combines modules in dependency order
- **Output**: Single PowerShell script with all modules embedded
- **Features**: Removes dot-sourcing, maintains execution order

### Build-Executable.ps1
- **Input**: Bundled PowerShell script
- **Process**: Uses PS2EXE to convert script to executable
- **Output**: Standalone Windows executable
- **Features**: Admin requirements, metadata embedding, error handling

### Install-Requirements.ps1
- **Purpose**: Installs all build dependencies
- **Installs**: PS2EXE module for script-to-executable conversion
- **Scope**: Current user (no admin required for module installation)
