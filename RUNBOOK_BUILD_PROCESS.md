# ESS Health Checker - Build Process Runbook

## 📋 Overview

This runbook provides step-by-step instructions for building and deploying the ESS Pre-Upgrade Health Checker as a standalone executable. The build process converts multiple PowerShell modules into a single executable file for easy distribution.

## 🎯 Purpose

Transform the ESS Health Checker from a multi-file PowerShell project into a single, portable executable that can run on any Windows machine without requiring folder structures or external dependencies.

## 📁 Project Structure

```
C:\MAC\refactor693callstack\
├── src/                           # Source PowerShell modules
│   ├── Core/                      # Core functionality
│   ├── Detection/                 # ESS/WFE detection
│   ├── Validation/                # Health check validations
│   ├── SystemInfo/                # System information collection
│   ├── Interactive/               # Interactive mode functionality
│   └── Utils/                     # Helper functions
├── Build-BundledScript.ps1        # Creates single PS1 file
├── Build-Executable.ps1           # Complete build automation
├── RunHealthCheck.ps1             # Original automated launcher
├── RunInteractiveHealthCheck.ps1  # Original interactive launcher
├── ESSHealthChecker-Complete.ps1  # Generated bundled script
└── ESSHealthChecker.exe           # Generated executable
```

## 🔧 Prerequisites

### Software Requirements
- **Windows 10/11** or **Windows Server 2016+**
- **PowerShell 5.1+** or **PowerShell Core 7+**
- **PS2EXE module** for PowerShell-to-executable conversion
- **Administrator privileges** (for building and testing)

### Environment Setup
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Install PS2EXE module
Install-Module ps2exe -Force -Scope CurrentUser

# Verify installation
Get-Module -ListAvailable ps2exe
```

## 🚀 Build Process

### Method 1: Automated Build (Recommended)

#### Step 1: Run Complete Build Process
```powershell
# Navigate to project directory
cd "C:\MAC\refactor693callstack"

# Run automated build with PS2EXE installation
.\Build-Executable.ps1 -InstallPS2EXE
```

#### Step 2: Verify Build Output
```powershell
# Check generated files
ls ESSHealthChecker*.ps1, ESSHealthChecker*.exe

# Expected output:
# ESSHealthChecker-Complete.ps1  (~240 KB)
# ESSHealthChecker.exe           (~2-4 MB)
```

### Method 2: Manual Build Process

#### Step 1: Create Bundled Script
```powershell
# Bundle all PowerShell modules into single script
.\Build-BundledScript.ps1

# Output: ESSHealthChecker-Complete.ps1
```

#### Step 2: Convert to Executable
```powershell
# Import PS2EXE module
Import-Module ps2exe

# Convert bundled script to executable
ps2exe -inputFile "ESSHealthChecker-Complete.ps1" `
       -outputFile "ESSHealthChecker.exe" `
       -requireAdmin `
       -verbose `
       -title "ESS Pre-Upgrade Health Checker" `
       -description "MYOB PayGlobal ESS Health Check Tool" `
       -company "MYOB" `
       -product "ESS Health Checker" `
       -copyright "© 2025 MYOB" `
       -version "3.0.0.0"
```

#### Step 3: Test the Executable
```powershell
# Test the generated executable
.\ESSHealthChecker.exe

# Should display:
# - Menu with 3 options (Automated, Interactive, Exit)
# - No errors during module loading
# - Successful health check execution
```

## 📊 Build Validation

### Pre-Build Checklist
- [ ] All source modules in `src/` directory are present
- [ ] No syntax errors in PowerShell scripts
- [ ] PS2EXE module is installed and accessible
- [ ] Build directory has write permissions
- [ ] PowerShell execution policy allows script execution

### Post-Build Verification

#### Test 1: Executable Creation
```powershell
# Verify executable exists and has expected size (2-4 MB)
Get-ChildItem ESSHealthChecker.exe | Select-Object Name, Length

# Check executable properties
Get-ItemProperty ESSHealthChecker.exe | Select-Object VersionInfo
```

#### Test 2: Functionality Testing
```powershell
# Test menu display (should show 3 options)
echo "3" | .\ESSHealthChecker.exe  # Should exit cleanly

# Test automated mode
.\ESSHealthChecker.exe -NoConsole  # Should run without prompts

# Test interactive mode
.\ESSHealthChecker.exe -Interactive  # Should show instance selection
```

#### Test 3: Report Generation
```powershell
# Check report generation
# Run health check and verify report creation in Reports/ folder
Get-ChildItem Reports\ | Sort-Object LastWriteTime -Descending | Select-Object -First 3
```

## 🔄 Rebuild Process

### When to Rebuild
- **Source code changes** in any `src/` module
- **New features added** to the health checker
- **Bug fixes applied** to existing functionality
- **Configuration updates** in validation logic

### Quick Rebuild Steps
```powershell
# 1. Navigate to project directory
cd "C:\MAC\refactor693callstack"

# 2. Rebuild bundled script (incorporates all changes)
.\Build-BundledScript.ps1

# 3. Rebuild executable
ps2exe -inputFile "ESSHealthChecker-Complete.ps1" -outputFile "ESSHealthChecker.exe" -requireAdmin -verbose

# 4. Test rebuilt executable
.\ESSHealthChecker.exe
```

## 📦 Deployment

### Single File Deployment
```powershell
# Copy only the executable - no other files needed
Copy-Item "ESSHealthChecker.exe" "\\target-server\c$\Tools\"

# Or for USB/portable deployment
Copy-Item "ESSHealthChecker.exe" "E:\PortableTools\"
```

### Target Machine Requirements
- **Windows Server 2016+** or **Windows 10+**
- **PowerShell 5.1+** (usually pre-installed)
- **Administrator privileges** (for IIS/system checks)
- **IIS installed** (if checking IIS systems)

### Deployment Verification
```powershell
# On target machine, verify executable runs
.\ESSHealthChecker.exe

# Check report generation
ls Reports\
```

## 🛠️ Troubleshooting

### Common Build Issues

#### Issue 1: PS2EXE Module Not Found
```powershell
# Error: "ps2exe command not found"
# Solution: Install PS2EXE module
Install-Module ps2exe -Force -Scope CurrentUser
Import-Module ps2exe
```

#### Issue 2: Bundled Script Syntax Errors
```powershell
# Error: Script has syntax errors
# Solution: Check individual module syntax
Get-ChildItem src\ -Recurse -Filter "*.ps1" | ForEach-Object {
    Write-Host "Checking: $($_.Name)"
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$null)
}
```

#### Issue 3: Executable Path Errors
```powershell
# Error: "Cannot bind argument to parameter 'Path'"
# Solution: Rebuild with latest fixes
.\Build-BundledScript.ps1  # Ensures path fixes are included
```

#### Issue 4: Module Loading Errors
```powershell
# Error: Functions not found in executable
# Solution: Verify all modules are included in build order
# Check Build-BundledScript.ps1 $moduleOrder array
```

### Runtime Issues

#### Issue 1: "Unknown Publisher" Warning
- **Cause**: Executable is not code-signed
- **Solution**: Click "More info" → "Run anyway"
- **Prevention**: Code signing certificate (optional, $200-400/year)

#### Issue 2: Permission Denied
- **Cause**: Insufficient privileges
- **Solution**: Run as Administrator
- **Command**: `Right-click → "Run as Administrator"`

#### Issue 3: PowerShell Not Found
- **Cause**: PowerShell not installed on target machine
- **Solution**: Install PowerShell 5.1+ or PowerShell Core

## 📝 Maintenance

### Regular Maintenance Tasks
- **Monthly**: Verify build process still works
- **After OS updates**: Test executable compatibility
- **After PowerShell updates**: Rebuild and test
- **After source changes**: Rebuild and deploy

### Version Control
```powershell
# Tag releases for version tracking
git tag -a "v3.0.0" -m "Single executable release"
git push origin v3.0.0

# Keep build artifacts in separate branch
git checkout -b builds
git add ESSHealthChecker.exe ESSHealthChecker-Complete.ps1
git commit -m "Build artifacts for v3.0.0"
```

## 📈 Success Metrics

### Build Success Indicators
- ✅ **Executable created** (2-4 MB size)
- ✅ **No build errors** during conversion
- ✅ **All modules embedded** (17 modules total)
- ✅ **Menu displays correctly**
- ✅ **Health checks run successfully**
- ✅ **Reports generate without errors**

### Deployment Success Indicators
- ✅ **Executable runs on target machines**
- ✅ **Reports folder created automatically**
- ✅ **Health checks complete successfully**
- ✅ **No external dependencies required**

## 📞 Support and Contacts

### Build Issues
- **Primary Contact**: Zoe Lai (Build Process Owner)
- **Escalation**: MYOB Technical Team
- **Documentation**: This runbook + source code comments

### Runtime Issues
- **User Support**: IT Helpdesk
- **Technical Support**: PowerShell/ESS Team
- **Emergency**: System Administrator

---

## 📚 Appendix

### A. Build Script Parameters

#### Build-BundledScript.ps1
- `-OutputFile`: Custom output filename (default: ESSHealthChecker-Complete.ps1)
- `-SourceDirectory`: Source modules directory (default: src)

#### Build-Executable.ps1
- `-InstallPS2EXE`: Automatically install PS2EXE module
- `-SkipTest`: Skip syntax validation testing
- `-OutputExe`: Custom executable name (default: ESSHealthChecker.exe)

### B. PS2EXE Parameters Reference
```powershell
ps2exe -inputFile "script.ps1" -outputFile "app.exe" [options]

# Key options:
-requireAdmin     # Require administrator privileges
-verbose          # Show detailed conversion output
-noConsole        # Hide console window (GUI mode)
-iconFile         # Custom icon file
-title            # Executable title
-description      # Executable description
-company          # Company name
-product          # Product name
-copyright        # Copyright notice
-version          # Version number
```

### C. File Size References
- **Source modules**: ~150 KB total
- **Bundled script**: ~240 KB
- **Final executable**: 2-4 MB (includes PowerShell runtime)

---

*Last Updated: September 12, 2025*
*Version: 1.0*
*Author: ESS Health Checker Team*
