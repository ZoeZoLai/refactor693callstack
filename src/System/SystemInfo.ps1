<#
.SYNOPSIS
    Consolidated system information collection module
.DESCRIPTION
    Collects comprehensive system information including hardware, OS, IIS, and SQL Server
.NOTES
    Author: Zoe Lai
    Date: 23/08/2025
    Version: 2.0 - Simplified Structure
#>

function Get-HardwareInformation {
    <#
    .SYNOPSIS
        Get hardware information of the system.
    #>
    
    try {
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        $processors = Get-CimInstance Win32_Processor
        $physicalMemory = Get-CimInstance Win32_PhysicalMemory
        $logicalDisks = Get-CimInstance Win32_LogicalDisk

        $totalMemory = ($physicalMemory | Measure-Object -Property Capacity -Sum).Sum
        $totalCores = ($processors | Measure-Object -Property NumberOfCores -Sum).Sum
        $totalLogicalProcessors = ($processors | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        
        # Calculate processor speed information
        $processorSpeeds = $processors | ForEach-Object { $_.MaxClockSpeed }
        $averageProcessorSpeed = ($processorSpeeds | Measure-Object -Average).Average
        $minProcessorSpeed = ($processorSpeeds | Measure-Object -Minimum).Minimum
        $maxProcessorSpeed = ($processorSpeeds | Measure-Object -Maximum).Maximum

        return @{
            Manufacturer = $computerSystem.Manufacturer
            Model = $computerSystem.Model
            TotalPhysicalMemory = [Math]::Round($totalMemory / 1GB, 2)
            TotalCores = $totalCores
            TotalLogicalProcessors = $totalLogicalProcessors
            AverageProcessorSpeedGHz = [Math]::Round($averageProcessorSpeed / 1000, 2)
            MinProcessorSpeedGHz = [Math]::Round($minProcessorSpeed / 1000, 2)
            MaxProcessorSpeedGHz = [Math]::Round($maxProcessorSpeed / 1000, 2)
            Processors = $processors | ForEach-Object {
                @{
                    Name = $_.Name
                    Cores = $_.NumberOfCores
                    LogicalProcessors = $_.NumberOfLogicalProcessors
                    MaxClockSpeed = [Math]::Round($_.MaxClockSpeed / 1000, 2)
                    CurrentClockSpeed = [Math]::Round($_.CurrentClockSpeed / 1000, 2)
                }
            }
            LogicalDisks = $logicalDisks | ForEach-Object {
                @{
                    DeviceID = $_.DeviceID
                    Size = [Math]::Round($_.Size / 1GB, 2)
                    FreeSpace = [Math]::Round($_.FreeSpace / 1GB, 2)
                    FileSystem = $_.FileSystem
                }
            }
        }
    }
    catch {
        Write-Warning "Could not retrieve hardware information: $_"
        return @{}
    }
}

function Get-NetworkInformation {
    <#
    .SYNOPSIS
        Get network information of the system.
    #>
    
    try {
        $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        $ipConfig = Get-NetIPConfiguration | Where-Object { $_.IPv4Address}
        $dnsServers = Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses }
        
        return @{
            NetworkAdapters = $networkAdapters | ForEach-Object {
                @{
                    Name = $_.Name
                    InterfaceDescription = $_.InterfaceDescription
                    Status = $_.Status
                    MACAddress = $_.MacAddress
                }
            }
            IPConfigurations = $ipConfig | ForEach-Object {
                @{
                    InterfaceAlias = $_.InterfaceAlias
                    IPv4Address = $_.IPv4Address.IPAddressToString
                    IPv4DefaultGateway = $_.IPv4DefaultGateway.NextHop
                    SubnetMask = $_.IPv4Address.PrefixLength
                }
            }
            DNSServers = $dnsServers | ForEach-Object {
                @{
                    InterfaceAlias = $_.InterfaceAlias
                    ServerAddresses = $_.ServerAddresses
                }
            }
        }
    }
    catch {
        Write-Warning "Could not retrieve network information: $_"
        return @{}  
    }
}

function Get-OSInformation {
    <#
    .SYNOPSIS
        Get operating system information.
    #>
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $osVersion = [System.Environment]::OSVersion

        return @{
            Caption = $os.Caption
            Version = $os.Version
            BuildNumber = $os.BuildNumber
            ServicePack = $os.ServicePackMajorVersion
            TotalVisibleMemory = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            FreePhysicalMemory = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
            Platform = $osVersion.Platform
            MajorVersion = $osVersion.Version.Major
            MinorVersion = $osVersion.Version.Minor
            IsServer = $os.ProductType -eq 3
        }
    }
    catch {
        Write-Warning "Could not retrieve OS information: $_"
        return @{}
    }
}

function Get-RegistryInformation {
    <#
    .SYNOPSIS
        Get relevant registry information.
    #>
    
    try {
        $dotNetVersions = @()
        
        # Check for .NET Framework 4.x versions
        $dotNetKeys = @(
            "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full",
            "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client"
        )
        
        foreach ($key in $dotNetKeys) {
            $version = Get-ItemProperty -Path $key -Name "Version" -ErrorAction SilentlyContinue
            if ($version) {
                $dotNetVersions += $version.Version
            }
        }
        
        # Also check for .NET Framework 3.x versions
        $dotNet3Keys = @(
            "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5",
            "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0"
        )
        
        foreach ($key in $dotNet3Keys) {
            $install = Get-ItemProperty -Path $key -Name "Install" -ErrorAction SilentlyContinue
            if ($install -and $install.Install -eq 1) {
                $version = Get-ItemProperty -Path $key -Name "Version" -ErrorAction SilentlyContinue
                if ($version) {
                    $dotNetVersions += $version.Version
                }
            }
        }
        
        # Check for .NET Framework 2.x
        $dotNet2Key = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
        $install = Get-ItemProperty -Path $dotNet2Key -Name "Install" -ErrorAction SilentlyContinue
        if ($install -and $install.Install -eq 1) {
            $version = Get-ItemProperty -Path $dotNet2Key -Name "Version" -ErrorAction SilentlyContinue
            if ($version) {
                $dotNetVersions += $version.Version
            }
        }
        
        # Remove duplicates and sort
        $dotNetVersions = $dotNetVersions | Sort-Object -Unique

        return @{
            DotNetVersions = $dotNetVersions
        }
    }
    catch {
        Write-Warning "Could not retrieve registry information: $_"
        return @{}
    }
}

function Get-IISInformation {
    <#
    .SYNOPSIS
        Get IIS information of the system.
    #>

    try {
        # Check if IIS is installed - Compatible with both Windows Server and Client
        $iisInstalled = $false
        $iisVersion = $null
        
        # Try Windows Server method first
        try {
            if (Get-Command "Get-WindowsFeature" -ErrorAction SilentlyContinue) {
                $webServerFeature = Get-WindowsFeature -Name "Web-Server" -ErrorAction SilentlyContinue
                $iisInstalled = $webServerFeature -and $webServerFeature.InstallState -eq "Installed"
            }
        }
        catch {
            # Windows Server method failed, continue to registry method
        }
        
        # If Windows Server method didn't work, try registry method (Windows Client/Server)
        if (-not $iisInstalled) {
            $iisRegKey = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp" -ErrorAction SilentlyContinue
            $iisInstalled = $null -ne $iisRegKey
        }
        
        # Additional check for IIS installation via service
        if (-not $iisInstalled) {
            try {
                $w3svcService = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
                $iisInstalled = $w3svcService -and $w3svcService.Status -eq "Running"
            }
            catch {
                # Service check failed, continue
            }
        }
        
        # Get IIS version from registry
        if ($iisInstalled) {
            $versionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp" -ErrorAction SilentlyContinue
            if ($versionInfo) {
                $iisVersion = "$($versionInfo.MajorVersion).$($versionInfo.MinorVersion)"
            }
        }

        if ($iisInstalled) {
            # Import IIS modules if available
            try {
                Import-Module WebAdministration -ErrorAction SilentlyContinue
                Import-Module IISAdministration -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Could not import IIS modules, trying alternative methods"
            }
            
            # Get sites using multiple methods
            $sites = @()
            try {
                # Try IISAdministration module first
                if (Get-Command "Get-IISSite" -ErrorAction SilentlyContinue) {
                    $sites = Get-IISSite -ErrorAction SilentlyContinue
                    Write-Verbose "Found $($sites.Count) sites using Get-IISSite"
                }
                # Fallback to WebAdministration module
                elseif (Get-Command "Get-Website" -ErrorAction SilentlyContinue) {
                    $sites = Get-Website -ErrorAction SilentlyContinue
                    Write-Verbose "Found $($sites.Count) sites using Get-Website"
                }
            }
            catch {
                if ($_.Exception.Message -like "*insufficient permissions*" -or $_.Exception.Message -like "*redirection.config*") {
                    Write-Warning "Could not retrieve IIS sites due to insufficient permissions. Run as Administrator to access IIS configuration."
                } else {
                    Write-Warning "Could not retrieve IIS sites: $_"
                }
            }
            
            # Get application pools
            $appPools = @()
            try {
                # Try IISAdministration module first (new method)
                if (Get-Command "Get-IISAppPool" -ErrorAction SilentlyContinue) {
                    $appPools = Get-IISAppPool -ErrorAction SilentlyContinue
                }
                # Fallback try older method via WebAdministration module
                elseif (Get-Command "Get-ChildItem" -ErrorAction SilentlyContinue) {
                    # Use IIS provider to get application pools
                    $appPools = Get-ChildItem IIS:\AppPools -ErrorAction SilentlyContinue
                }
            }
            catch {
                if ($_.Exception.Message -like "*insufficient permissions*" -or $_.Exception.Message -like "*redirection.config*") {
                    Write-Warning "Could not retrieve IIS application pools due to insufficient permissions. Run as Administrator to access IIS configuration."
                } else {
                    Write-Warning "Could not retrieve IIS application pools: $_"
                }
            }
            
            # Process sites and their applications
            $processedSites = @()
            foreach ($site in $sites) {
                Write-Verbose "Processing site: $($site.Name)"
                
                # Get applications for this site
                $siteApplications = @()
                try {
                    if (Get-Command "Get-IISApplication" -ErrorAction SilentlyContinue) {
                        $siteApplications = Get-IISSite -Name $site.Name | Get-IISApplication -ErrorAction SilentlyContinue
                    }
                    elseif (Get-Command "Get-WebApplication" -ErrorAction SilentlyContinue) {
                        $siteApplications = Get-WebApplication -Site $site.Name -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Verbose "Could not get applications for site $($site.Name): $_"
                }
                
                # Process applications with detailed information
                $processedApplications = @()
                foreach ($app in $siteApplications) {
                    Write-Verbose "Processing application: $($app.Path) in site: $($site.Name)"
                    
                    # Get virtual directories for this application
                    $virtualDirectories = @()
                    try {
                        if (Get-Command "Get-IISVirtualDirectory" -ErrorAction SilentlyContinue) {
                            $virtualDirectories = Get-IISSite -Name $site.Name | Get-IISApplication -Path $app.Path | Get-IISVirtualDirectory -ErrorAction SilentlyContinue
                        }
                        elseif (Get-Command "Get-WebVirtualDirectory" -ErrorAction SilentlyContinue) {
                            $virtualDirectories = Get-WebVirtualDirectory -Site $site.Name -Application $app.Path -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        Write-Verbose "Could not get virtual directories for application $($app.Path): $_"
                    }
                    
                    $appInfo = @{
                        Name = $app.Path.TrimStart('/')
                        Path = $app.Path
                        PhysicalPath = if ($virtualDirectories.Count -gt 0) { $virtualDirectories[0].PhysicalPath } else { $app.PhysicalPath }
                        ApplicationPool = $app.ApplicationPool
                        Protocols = $app.EnabledProtocols
                        State = $app.State
                        VirtualDirectories = $virtualDirectories | ForEach-Object {
                            @{
                                Path = $_.Path
                                PhysicalPath = $_.PhysicalPath
                            }
                        }
                    }
                    
                    $processedApplications += $appInfo
                }
                
                # Add site information
                $siteInfo = @{
                    Name = $site.Name
                    ID = $site.ID
                    State = $site.State
                    PhysicalPath = $site.PhysicalPath
                    Bindings = $site.Bindings
                    Applications = $processedApplications
                }
                
                $processedSites += $siteInfo
            }
            
            # Process application pools with detailed information
            $processedAppPools = $appPools | ForEach-Object {
                @{
                    Name = $_.Name
                    State = $_.State
                    ManagedRuntimeVersion = $_.ManagedRuntimeVersion
                    ManagedPipelineMode = $_.ManagedPipelineMode
                    StartMode = $_.StartMode
                    ProcessModel = @{
                        IdentityType = $_.ProcessModel.IdentityType
                        UserName = $_.ProcessModel.UserName
                    }
                    Recycling = @{
                        PeriodicRestart = $_.Recycling.PeriodicRestart
                        Time = $_.Recycling.Time
                    }
                }
            }

            return @{
                IsInstalled = $true
                Version = $iisVersion
                Sites = $processedSites
                ApplicationPools = $processedAppPools
                TotalSites = $sites.Count
                TotalApplications = ($processedSites | ForEach-Object { $_.Applications.Count } | Measure-Object -Sum).Sum
                TotalAppPools = $appPools.Count
            }
        } else {
            return @{ IsInstalled = $false }
        }
        
    }
    catch {
        Write-Warning "Could not retrieve IIS information: $_"
        return @{ IsInstalled = $false }
    }
}

function Get-SQLServerInformation {
    <#
    .SYNOPSIS
        Get SQL Server installation information.
    .DESCRIPTION
        Detects SQL Server installations and running services.
    .RETURNS
        Object containing SQL Server information.
    #>
    
    try {
        $sqlInfo = @{
            IsInstalled = $false
            Instances = @()
            Services = @()
            Versions = @()
        }
        
        # Check for SQL Server services
        $sqlServices = Get-Service -Name "*SQL*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
        if ($sqlServices) {
            $sqlInfo.IsInstalled = $true
            $sqlInfo.Services = $sqlServices | ForEach-Object {
                @{
                    Name = $_.Name
                    DisplayName = $_.DisplayName
                    Status = $_.Status
                    StartType = $_.StartType
                }
            }
        }
        
        # Check for SQL Server instances via registry
        $sqlInstances = @()
        $sqlKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server"
        )
        
        foreach ($key in $sqlKeys) {
            if (Test-Path $key) {
                try {
                    $installedInstancesPath = "$key\Instance Names\SQL"
                    if (Test-Path $installedInstancesPath) {
                        $instanceNames = Get-ItemProperty -Path $installedInstancesPath -ErrorAction SilentlyContinue
                        if ($instanceNames) {
                            foreach ($property in $instanceNames.PSObject.Properties) {
                                if ($property.Name -notlike "PS*") {
                                    $sqlInstances += $property.Name
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Could not read SQL instances from registry: $_"
                }
            }
        }
        
        if ($sqlInstances.Count -gt 0) {
            $sqlInfo.IsInstalled = $true
            $sqlInfo.Instances = $sqlInstances
        }
        
        # Check for SQL Server versions with mapping
        $sqlVersions = @()
        $versionMapping = @{
            "160" = "SQL Server 2022"
            "150" = "SQL Server 2019"
            "140" = "SQL Server 2017"
            "130" = "SQL Server 2016"
            "120" = "SQL Server 2014"
            "110" = "SQL Server 2012"
            "100" = "SQL Server 2008/2008 R2"
            "90"  = "SQL Server 2005"
            "80"  = "SQL Server 2000"
        }
        
        $versionKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\*"
        )
        
        foreach ($pattern in $versionKeys) {
            $keys = Get-ItemProperty -Path $pattern -ErrorAction SilentlyContinue
            foreach ($key in $keys) {
                if ($key.PSChildName -match "^\d+$") {
                    $versionNumber = $key.PSChildName
                    if ($versionMapping.ContainsKey($versionNumber)) {
                        $sqlVersions += $versionMapping[$versionNumber]
                    } else {
                        $sqlVersions += "SQL Server (Version $versionNumber)"
                    }
                }
            }
        }
        
        if ($sqlVersions.Count -gt 0) {
            $sqlInfo.Versions = $sqlVersions | Sort-Object -Unique
        }
        
        return $sqlInfo
    }
    catch {
        Write-Warning "Could not retrieve SQL Server information: $_"
        return @{
            IsInstalled = $false
            Instances = @()
            Services = @()
            Versions = @()
        }
    }
}

function Get-SystemInformation {
    <#
    .SYNOPSIS
        Gets comprehensive system information
    .DESCRIPTION
        Collects all system information including hardware, OS, IIS, SQL, and network
    .RETURNS
        Hashtable containing all system information
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Collecting system information..." -ForegroundColor Yellow
        
        $systemInfo = @{
            ComputerName = $env:COMPUTERNAME
            Timestamp = Get-Date
            Hardware = Get-HardwareInformation
            OS = Get-OSInformation
            Registry = Get-RegistryInformation
            IIS = Get-IISInformation
            SQL = Get-SQLServerInformation
            Network = Get-NetworkInformation
        }
        
        Write-Host "System information collected successfully" -ForegroundColor Green
        return $systemInfo
    }
    catch {
        Write-Error "Failed to collect system information: $_"
        throw
    }
}
