# ESS Pre-Upgrade Health Checker - PowerShell Module Manifest
# PowerShell Module Requirements Definition
# Version: 3.0.0

@{
    # Basic Information
    ModuleVersion = '3.0.0'
    GUID = '12345678-1234-5678-9012-123456789012'
    Author = 'Zoe Lai'
    CompanyName = 'MYOB'
    Copyright = '© 2025 MYOB. All rights reserved.'
    Description = 'ESS Pre-Upgrade Health Checker - Comprehensive health validation for MYOB PayGlobal ESS systems'
    
    # PowerShell Requirements
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # .NET Framework Requirements
    DotNetFrameworkVersion = '4.8'
    CLRVersion = '4.0'
    
    # Required Modules
    RequiredModules = @(
        @{
            ModuleName = 'WebAdministration'
            ModuleVersion = '1.0.0.0'
            GUID = 'a0504b02-24e1-4a49-98c7-b4a1ee59e9d9'
        },
        @{
            ModuleName = 'IISAdministration' 
            ModuleVersion = '1.1.0.0'
            GUID = '874a9d35-2108-4b02-8b4a-98b09dd4db71'
        }
    )
    
    # Optional Modules (Development/Build)
    RequiredModulesForBuild = @(
        'ps2exe'
    )
    
    # Optional Modules (Enhanced Functionality)
    OptionalModules = @(
        'SqlServer'
    )
    
    # Processor Architecture
    ProcessorArchitecture = 'None'  # Works on x86, x64, ARM
    
    # Required Assemblies
    RequiredAssemblies = @(
        'System.Collections',
        'System.Net',
        'System.Management.Automation',
        'System.Security.Principal',
        'System.Environment',
        'System.IO',
        'System.Text'
    )
    
    # Scripts to run before module import
    ScriptsToProcess = @()
    
    # Type files to load
    TypesToProcess = @()
    
    # Format files to load  
    FormatsToProcess = @()
    
    # Nested modules
    NestedModules = @()
    
    # Functions to export
    FunctionsToExport = @(
        'Start-ESSHealthChecks',
        'Start-InteractiveESSHealthChecks',
        'New-ESSConfiguration',
        'Get-ESSConfiguration',
        'Add-HealthCheckResult',
        'Get-HealthCheckResults',
        'Get-HealthCheckSummary'
    )
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Module list
    ModuleList = @()
    
    # File list
    FileList = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            # Tags for PowerShell Gallery
            Tags = @('ESS', 'HealthCheck', 'MYOB', 'PayGlobal', 'IIS', 'Validation', 'PreUpgrade')
            
            # License URI
            LicenseUri = ''
            
            # Project URI
            ProjectUri = ''
            
            # Icon URI
            IconUri = ''
            
            # Release notes
            ReleaseNotes = @'
Version 3.0.0 - September 2025
- Added standalone executable support via PS2EXE
- Enhanced error handling for bundled deployments
- Improved path resolution for different execution contexts
- Complete build automation with validation
- Comprehensive documentation and runbooks

Version 2.2.0 - August 2025
- Implemented call stack principles architecture
- Eliminated all global variables
- Added dependency injection throughout
- Enhanced testability and maintainability
- Improved interactive mode functionality

Version 2.1.0 - July 2025
- Added interactive health check mode
- Enhanced ESS/WFE detection capabilities
- Improved API health check validation
- Better error reporting and logging
'@
            
            # Prerelease suffix
            Prerelease = ''
            
            # External module dependencies
            ExternalModuleDependencies = @('WebAdministration', 'IISAdministration')
            
            # Required license acceptance
            RequireLicenseAcceptance = $false
        }
        
        # Build Requirements
        BuildRequirements = @{
            MinimumPowerShellVersion = '5.1'
            RequiredModules = @('ps2exe')
            BuildTools = @('PowerShell ISE', 'Visual Studio Code')
            OperatingSystems = @('Windows Server 2016+', 'Windows 10+')
        }
        
        # Runtime Requirements  
        RuntimeRequirements = @{
            WindowsFeatures = @(
                'IIS-WebServerRole',
                'IIS-WebServer', 
                'IIS-ManagementConsole'
            )
            Privileges = @(
                'Administrator',
                'IIS_IUSRS',
                'Registry Read Access'
            )
            NetworkAccess = @(
                'HTTP/HTTPS outbound',
                'SQL Server connectivity'
            )
        }
        
        # Compatibility Information
        Compatibility = @{
            TestedPlatforms = @(
                'Windows Server 2016 + PowerShell 5.1',
                'Windows Server 2019 + PowerShell 5.1', 
                'Windows Server 2022 + PowerShell 5.1',
                'Windows 10 + PowerShell 5.1',
                'Windows 11 + PowerShell 5.1',
                'Windows Server 2019 + PowerShell Core 7.x',
                'Windows Server 2022 + PowerShell Core 7.x'
            )
            KnownLimitations = @(
                'Linux: IIS modules not available',
                'macOS: Windows-specific features not available',
                'Windows Server 2012 R2: Limited testing'
            )
        }
        
        # Deployment Scenarios
        DeploymentScenarios = @{
            StandaloneExecutable = @{
                Description = 'Single EXE file deployment'
                Requirements = @('PowerShell 5.1+', 'Administrator rights')
                FilesNeeded = @('ESSHealthChecker.exe')
                Dependencies = @('None - all embedded')
            }
            PowerShellScripts = @{
                Description = 'Source file deployment'
                Requirements = @('Source files', 'Execution policy set')
                FilesNeeded = @('Complete src/ folder', 'Launcher scripts')
                Dependencies = @('All modules available')
            }
            Development = @{
                Description = 'Development environment'
                Requirements = @('Build tools', 'PS2EXE module', 'Git')
                FilesNeeded = @('Complete repository')
                Dependencies = @('Development tools + runtime requirements')
            }
        }
    }
    
    # Cmdlets and functions help URI
    HelpInfoURI = ''
    
    # Default command prefix
    DefaultCommandPrefix = ''
}
