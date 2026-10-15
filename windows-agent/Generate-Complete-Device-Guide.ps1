<#
===============================================================================
NEXORA-WINDOWS v20.0 APEX - COMPLETE DEVICE GUIDE GENERATOR (دليل الجهاز الكامل)
===============================================================================
File:        Generate-Complete-Device-Guide.ps1
Purpose:     100% Read-Only, Fault-Isolated, Privacy-Safe 16-Layer Windows
             Deep Collector that compiles the comprehensive Markdown Dossier:
             Complete_Device_Guide_<Hostname>_<Date>.md (دليل_الجهاز_الكامل.md)
             compatible with NEXORA-WINDOWS v20.0 APEX OMNI-MASTER Prompt.
Compatibility: Windows PowerShell 5.1+ and PowerShell 7+ (Windows 10/11/Server)
Safety:      ZERO state changes. Read-only WMI/CIM, Registry, EventLog, Winget.
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = [Environment]::GetFolderPath("Desktop"),

    [Parameter(Mandatory = $false)]
    [string]$CustomFileName = "",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeJsonExport,

    [Parameter(Mandatory = $false)]
    [switch]$OpenWhenDone
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$ScriptStartTime = Get-Date
$RunId = [guid]::NewGuid().ToString().Substring(0, 8).ToUpper()
$HostName = $env:COMPUTERNAME
$DateStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    try {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    } catch {
        $OutputDirectory = [Environment]::GetFolderPath("Desktop")
    }
}

if ([string]::IsNullOrWhiteSpace($CustomFileName)) {
    $FileName = "Complete_Device_Guide_${HostName}_${DateStamp}.md"
} else {
    $FileName = $CustomFileName
    if (-not $FileName.EndsWith(".md")) { $FileName += ".md" }
}

$OutputFilePath = Join-Path -Path $OutputDirectory -ChildPath $FileName
$JsonFilePath   = Join-Path -Path $OutputDirectory -ChildPath ($FileName -replace '\.md$', '.json')

# Check Elevation
$IsAdmin = $false
try {
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    $IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

# Coverage Ledger Tracker
$CoverageLedger = New-Object System.Collections.Generic.List[object]
$ExpertAlerts   = New-Object System.Collections.Generic.List[object]
$FullTelemetry  = [ordered]@{}

function Invoke-SafeCollector {
    param(
        [string]$LayerId,
        [string]$LayerName,
        [bool]$RequiresAdmin = $false,
        [scriptblock]$CollectorBlock
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host "[NEXORA] Collecting $LayerId - $LayerName ..." -ForegroundColor Cyan
    $status = "OK"
    $notes  = "Complete"
    $data   = $null
    try {
        if ($RequiresAdmin -and (-not $IsAdmin)) {
            $status = "PARTIAL (Not Elevated)"
            $notes  = "Session is Standard User; elevation-sensitive counters may be limited."
        }
        $data = & $CollectorBlock
    } catch {
        $status = "FAILED"
        $notes  = $_.Exception.Message -replace '[\r\n]+', ' '
    }
    $sw.Stop()
    $CoverageLedger.Add([PSCustomObject]@{
        Layer       = $LayerId
        Name        = $LayerName
        Status      = $status
        DurationMs  = $sw.ElapsedMilliseconds
        Notes       = $notes
    }) | Out-Null
    $FullTelemetry[$LayerId] = $data
    return $data
}

function Add-Alert {
    param(
        [string]$Severity, # CRITICAL, IMPORTANT, FYI
        [string]$Domain,
        [string]$Title,
        [string]$Evidence,
        [string]$Recommendation,
        [string]$Tier
    )
    $ExpertAlerts.Add([PSCustomObject]@{
        Severity       = $Severity
        Domain         = $Domain
        Title          = $Title
        Evidence       = $Evidence
        Recommendation = $Recommendation
        Tier           = $Tier
    }) | Out-Null
}

# ==============================================================================
# LAYER L01: IDENTITY, MOTHERBOARD & UEFI/BIOS
# ==============================================================================
$L01 = Invoke-SafeCollector -LayerId "L01" -LayerName "Identity, Motherboard & UEFI/BIOS" -CollectorBlock {
    $os   = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cs   = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    $bb   = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue
    $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
    $cv   = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue

    $secureBoot = "UNSUPPORTED_OR_LEGACY"
    try {
        $sb = Confirm-SecureBootUEFI -ErrorAction Stop
        $secureBoot = if ($sb) { "ENABLED" } else { "DISABLED" }
    } catch {
        $secureBoot = "UNAVAILABLE ($($_.Exception.Message))"
    }

    $fastStartup = "UNKNOWN"
    try {
        $fs = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue
        if ($null -ne $fs) {
            $fastStartup = if ($fs.HiberbootEnabled -eq 1) { "ENABLED (Hybrid Shutdown Active)" } else { "DISABLED (Clean Cold Boot)" }
        }
    } catch {}

    $uptimeDays = 0
    if ($os.LastBootUpTime) {
        $uptimeSpan = (Get-Date) - $os.LastBootUpTime
        $uptimeDays = [math]::Round($uptimeSpan.TotalDays, 2)
        if ($uptimeDays -gt 14) {
            Add-Alert -Severity "FYI" -Domain "L01-Platform" -Title "High System Uptime ($uptimeDays days)" `
                -Evidence "LastBootUpTime = $($os.LastBootUpTime) (FastStartup = $fastStartup)" `
                -Recommendation "Perform a true Restart (not Shutdown) so pending kernel/driver transactions clear." -Tier "T1"
        }
    }

    [PSCustomObject]@{
        Hostname        = $HostName
        OSCaption       = $os.Caption
        OSVersion       = $os.Version
        OSBuild         = "$($cv.CurrentBuild).$($cv.UBR)"
        DisplayVersion  = $cv.DisplayVersion
        EditionID       = $cv.EditionID
        InstallDate     = $os.InstallDate
        LastBootUpTime  = $os.LastBootUpTime
        UptimeDays      = $uptimeDays
        Architecture    = $os.OSArchitecture
        Manufacturer    = $cs.Manufacturer
        SystemModel     = $cs.Model
        BaseBoardVendor = $bb.Manufacturer
        BaseBoardModel  = $bb.Product
        BIOSVendor      = $bios.Manufacturer
        BIOSVersion     = $bios.SMBIOSBIOSVersion
        BIOSReleaseDate = $bios.ReleaseDate
        SecureBoot      = $secureBoot
        FastStartup     = $fastStartup
        DomainOrWorkgrp = $cs.Domain
        PartOfDomain    = $cs.PartOfDomain
        IsElevatedAdmin = $IsAdmin
        TimeZone        = (Get-TimeZone).Id
    }
}

# ==============================================================================
# LAYER L02: CPU ARCHITECTURE, CACHE & SCHEDULING
# ==============================================================================
$L02 = Invoke-SafeCollector -LayerId "L02" -LayerName "CPU Architecture, Cache & Virtualization" -CollectorBlock {
    $cpus = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue)
    $c = $cpus | Select-Object -First 1
    [PSCustomObject]@{
        Name                      = $c.Name
        Socket                    = $c.SocketDesignation
        PhysicalCores             = $c.NumberOfCores
        LogicalProcessors         = $c.NumberOfLogicalProcessors
        MaxClockMHz               = $c.MaxClockSpeed
        CurrentClockMHz           = $c.CurrentClockSpeed
        L2CacheKB                 = $c.L2CacheSize
        L3CacheKB                 = $c.L3CacheSize
        VirtualizationFirmwareOn  = $c.VirtualizationFirmwareEnabled
        VMMonitorModeExtensions   = $c.VMMonitorModeExtensions
        HypervisorPresent         = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
    }
}

# ==============================================================================
# LAYER L03: MEMORY (RAM) TOPOLOGY & PAGEFILE
# ==============================================================================
$L03 = Invoke-SafeCollector -LayerId "L03" -LayerName "Memory (RAM) Topology & Virtual Memory" -CollectorBlock {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    $dimms = @(Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue)
    $pf = @(Get-CimInstance -ClassName Win32_PageFileUsage -ErrorAction SilentlyContinue)

    $totalGB = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)
    $freeGB  = [math]::Round(($os.FreePhysicalMemory / 1MB), 2)
    $usedPct = if ($totalGB -gt 0) { [math]::Round((($totalGB - $freeGB) / $totalGB) * 100, 1) } else { 0 }

    $dimmList = foreach ($d in $dimms) {
        $capGB = [math]::Round($d.Capacity / 1GB, 1)
        if ($d.ConfiguredClockSpeed -gt 0 -and $d.Speed -gt 0 -and $d.ConfiguredClockSpeed -lt $d.Speed) {
            Add-Alert -Severity "IMPORTANT" -Domain "L03-Memory" -Title "RAM Running Below Rated XMP/EXPO Speed" `
                -Evidence "Slot $($d.DeviceLocator) rated $($d.Speed) MT/s is running at $($d.ConfiguredClockSpeed) MT/s" `
                -Recommendation "Enable XMP / EXPO / DOCP profile in BIOS/UEFI to unlock full memory bandwidth." -Tier "T3"
        }
        [PSCustomObject]@{
            Slot             = $d.DeviceLocator
            Bank             = $d.BankLabel
            Manufacturer     = $d.Manufacturer
            PartNumber       = ($d.PartNumber -replace '\s+', '')
            CapacityGB       = $capGB
            RatedSpeedMHz    = $d.Speed
            RunningSpeedMHz  = $d.ConfiguredClockSpeed
        }
    }

    if ($dimms.Count -eq 1) {
        Add-Alert -Severity "IMPORTANT" -Domain "L03-Memory" -Title "Single-Channel RAM Configuration Detected" `
            -Evidence "Only 1 DIMM slot populated ($totalGB GB total)" `
            -Recommendation "Single-channel memory severely bottlenecks CPU and 1% low gaming FPS. Dual-channel is recommended." -Tier "T3"
    }

    [PSCustomObject]@{
        TotalRAM_GB       = $totalGB
        FreeRAM_GB        = $freeGB
        UsedRAM_Percent   = $usedPct
        PopulatedSlots    = $dimms.Count
        ChannelEstimate   = if ($dimms.Count -ge 2) { "Dual/Multi-Channel ($($dimms.Count) DIMMs)" } elseif ($dimms.Count -eq 1) { "Single-Channel (1 DIMM)" } else { "Unknown" }
        DIMMs             = $dimmList
        PageFiles         = $pf | Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage
    }
}

# ==============================================================================
# LAYER L04: GRAPHICS (GPU), DISPLAY PIPELINE, HAGS, MPO & MONITORS
# ==============================================================================
$L04 = Invoke-SafeCollector -LayerId "L04" -LayerName "Graphics (GPU), Display Pipeline, HAGS & MPO" -CollectorBlock {
    $gpus = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue)
    $gfxReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -ErrorAction SilentlyContinue
    $dwmReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -ErrorAction SilentlyContinue

    $hagsState = switch ($gfxReg.HwSchMode) {
        2 { "ENABLED (HwSchMode=2)" }
        1 { "DISABLED (HwSchMode=1)" }
        default { "OS_DEFAULT ($($gfxReg.HwSchMode))" }
    }
    $mpoState = if ($dwmReg.OverlayTestMode -eq 5) { "DISABLED via OverlayTestMode=5" } else { "ENABLED (Default MPO)" }

    $gpuList = foreach ($g in $gpus) {
        [PSCustomObject]@{
            Name                = $g.Name
            DriverVersion       = $g.DriverVersion
            DriverDate          = $g.DriverDate
            Status              = $g.Status
            CurrentRefreshRate  = $g.CurrentRefreshRate
            MaxRefreshRate      = $g.MaxRefreshRate
            Resolution          = "$($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution)"
            PNPDeviceID         = $g.PNPDeviceID
        }
        if ($g.CurrentRefreshRate -eq 60 -and $g.MaxRefreshRate -gt 75) {
            Add-Alert -Severity "IMPORTANT" -Domain "L04-Display" -Title "High-Refresh Display Running at 60Hz" `
                -Evidence "$($g.Name) is running at 60Hz while MaxRefreshRate reports $($g.MaxRefreshRate)Hz" `
                -Recommendation "Open Windows Settings -> System -> Display -> Advanced display and set the highest Refresh Rate." -Tier "T1"
        }
    }

    [PSCustomObject]@{
        GPUs        = $gpuList
        HAGS        = $hagsState
        MPO         = $mpoState
        TdrDelay    = $gfxReg.TdrDelay
        TdrDdiDelay = $gfxReg.TdrDdiDelay
    }
}

# ==============================================================================
# LAYER L05: STORAGE MEDIA, SMART/NVME RELIABILITY & VOLUMES
# ==============================================================================
$L05 = Invoke-SafeCollector -LayerId "L05" -LayerName "Storage Media, SMART Counters & Volumes" -RequiresAdmin $true -CollectorBlock {
    $disks = @(Get-PhysicalDisk -ErrorAction SilentlyContinue)
    $diskList = foreach ($d in $disks) {
        $rel = $null
        try { $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue } catch {}
        $sizeGB = [math]::Round($d.Size / 1GB, 1)

        if ($d.HealthStatus -ne "Healthy" -or ($rel -and ($rel.ReadErrorsUncorrected -gt 0 -or $rel.WriteErrorsUncorrected -gt 0))) {
            Add-Alert -Severity "CRITICAL" -Domain "L05-Storage" -Title "Physical Disk Health / Uncorrected I/O Warning on $($d.FriendlyName)" `
                -Evidence "HealthStatus=$($d.HealthStatus), ReadErrors=$($rel.ReadErrorsUncorrected), WriteErrors=$($rel.WriteErrorsUncorrected), Wear=$($rel.Wear)%" `
                -Recommendation "STOP heavy writes immediately. Back up user data before any system repair or disk scan." -Tier "T3"
        }

        [PSCustomObject]@{
            FriendlyName           = $d.FriendlyName
            MediaType              = $d.MediaType
            BusType                = $d.BusType
            SizeGB                 = $sizeGB
            HealthStatus           = $d.HealthStatus
            OperationalStatus      = ($d.OperationalStatus -join ",")
            TemperatureC           = if ($rel) { $rel.Temperature } else { "N/A" }
            WearPercent            = if ($rel) { $rel.Wear } else { "N/A" }
            ReadErrorsUncorrected  = if ($rel) { $rel.ReadErrorsUncorrected } else { "N/A" }
            WriteErrorsUncorrected = if ($rel) { $rel.WriteErrorsUncorrected } else { "N/A" }
            PowerOnHours           = if ($rel) { $rel.PowerOnHours } else { "N/A" }
        }
    }

    $vols = @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter })
    $volList = foreach ($v in $vols) {
        $sizeGB = [math]::Round($v.Size / 1GB, 2)
        $freeGB = [math]::Round($v.SizeRemaining / 1GB, 2)
        $freePct = if ($sizeGB -gt 0) { [math]::Round(($freeGB / $sizeGB) * 100, 1) } else { 100 }

        if ($v.DriveLetter -eq 'C' -and $freePct -lt 12) {
            Add-Alert -Severity "IMPORTANT" -Domain "L05-Storage" -Title "Low Free Space on System Volume C: ($freePct%)" `
                -Evidence "C: has $freeGB GB free out of $sizeGB GB" `
                -Recommendation "Run P-CLEAN program to safely clear Shader Caches, Temp files, and superseded component packages." -Tier "T1"
        }

        [PSCustomObject]@{
            DriveLetter  = $v.DriveLetter
            Label        = $v.FileSystemLabel
            FileSystem   = $v.FileSystem
            SizeGB       = $sizeGB
            FreeGB       = $freeGB
            FreePercent  = $freePct
            HealthStatus = $v.HealthStatus
        }
    }

    [PSCustomObject]@{
        PhysicalDisks = $diskList
        Volumes       = $volList
    }
}

# ==============================================================================
# LAYER L06: POWER, BATTERY & THERMAL TELEMETRY
# ==============================================================================
$L06 = Invoke-SafeCollector -LayerId "L06" -LayerName "Power Plan, Battery Health & Thermal State" -CollectorBlock {
    $activePlan = (powercfg /getactivescheme 2>$null) -join " "
    $bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        ActivePowerPlan     = $activePlan
        BatteryPresent      = ($null -ne $bat)
        BatteryName         = if ($bat) { $bat.Name } else { "Desktop / No Battery" }
        BatteryChargeRemaining = if ($bat) { "$($bat.EstimatedChargeRemaining)%" } else { "N/A" }
    }
}

# ==============================================================================
# LAYER L07: DRIVERS, PNP PROBLEM DEVICES & KERNEL FILTERS
# ==============================================================================
$L07 = Invoke-SafeCollector -LayerId "L07" -LayerName "Drivers & Problem PnP Devices" -CollectorBlock {
    $probDevices = @(Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
        Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
        Select-Object Name, PNPClass, ConfigManagerErrorCode, DeviceID)

    if ($probDevices.Count -gt 0) {
        Add-Alert -Severity "IMPORTANT" -Domain "L07-Drivers" -Title "$($probDevices.Count) PnP Device(s) Reporting Error Codes" `
            -Evidence (($probDevices | ForEach-Object { "$($_.Name) [Code $($_.ConfigManagerErrorCode)]" }) -join "; ") `
            -Recommendation "Inspect Hardware IDs and install matching OEM/WHQL drivers." -Tier "T2"
    }

    $unsignedDrivers = @(Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
        Where-Object { $_.IsSigned -eq $false -and $_.DeviceName } |
        Select-Object DeviceName, DriverProviderName, DriverVersion, InfName -First 25)

    [PSCustomObject]@{
        ProblemDevices  = $probDevices
        UnsignedDrivers = $unsignedDrivers
    }
}

# ==============================================================================
# LAYER L08: SERVICES & TOP RESOURCE PROCESSES
# ==============================================================================
$L08 = Invoke-SafeCollector -LayerId "L08" -LayerName "Services & Top Resource Processes" -CollectorBlock {
    $stoppedAuto = @(Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue |
        Where-Object { $_.StartMode -eq "Auto" -and $_.State -ne "Running" -and $_.Name -notmatch '^(sppsvc|edgeupdate|gupdate|MapsBroker|WbioSrvc|RemoteRegistry|ShellHWDetection|TrustedInstaller)$' } |
        Select-Object Name, DisplayName, State, StartMode, ExitCode, PathName -First 30)

    $topProcs = @(Get-Process -ErrorAction SilentlyContinue |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 20 Name, Id, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}, @{N='CPU_Sec';E={[math]::Round($_.CPU,1)}}, Path)

    [PSCustomObject]@{
        StoppedAutoServices = $stoppedAuto
        TopProcessesByRAM   = $topProcs
    }
}

# ==============================================================================
# LAYER L09: PERSISTENCE, STARTUP & SCHEDULED TASKS
# ==============================================================================
$L09 = Invoke-SafeCollector -LayerId "L09" -LayerName "Startup Entries & Non-Microsoft Scheduled Tasks" -CollectorBlock {
    $startupCmds = @(Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction SilentlyContinue |
        Select-Object Name, Command, Location, User)

    $thirdPartyTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskPath -notlike "\Microsoft*" -and $_.State -ne "Disabled" } |
        Select-Object TaskName, TaskPath, Author, State -First 40)

    [PSCustomObject]@{
        StartupCommands          = $startupCmds
        ThirdPartyScheduledTasks = $thirdPartyTasks
    }
}

# ==============================================================================
# LAYER L10: DEEP DIAGNOSTIC REGISTRY MAP
# ==============================================================================
$L10 = Invoke-SafeCollector -LayerId "L10" -LayerName "Deep Diagnostic Registry Map" -CollectorBlock {
    $cbsReboot = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    $wuReboot  = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    $mmProfile = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -ErrorAction SilentlyContinue
    $gameTask  = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -ErrorAction SilentlyContinue

    if ($cbsReboot -or $wuReboot) {
        Add-Alert -Severity "IMPORTANT" -Domain "L10-Registry" -Title "Pending System Reboot Flag Active" `
            -Evidence "CBS_RebootPending=$cbsReboot, WU_RebootRequired=$wuReboot" `
            -Recommendation "Restart Windows before attempting any new updates, driver installs, or DISM repairs." -Tier "T1"
    }

    [PSCustomObject]@{
        CBS_RebootPending      = $cbsReboot
        WU_RebootRequired      = $wuReboot
        NetworkThrottlingIndex = $mmProfile.NetworkThrottlingIndex
        SystemResponsiveness   = $mmProfile.SystemResponsiveness
        Games_GPUPriority      = $gameTask.'GPU Priority'
        Games_Priority         = $gameTask.Priority
        Games_SchedulingCat    = $gameTask.'Scheduling Category'
    }
}

# ==============================================================================
# LAYER L11: NETWORK STACK, ADAPTERS, DNS & LISTENING PORTS
# ==============================================================================
$L11 = Invoke-SafeCollector -LayerId "L11" -LayerName "Network Stack, DNS, Hosts & Listening Ports" -CollectorBlock {
    $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } |
        Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress)
    $dns = @(Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.ServerAddresses } | Select-Object InterfaceAlias, @{N='DNSServers';E={$_.ServerAddresses -join ', '}})

    $hostsLines = @()
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (Test-Path $hostsPath) {
        $hostsLines = @(Get-Content $hostsPath -ErrorAction SilentlyContinue |
            Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' })
    }

    [PSCustomObject]@{
        ActiveAdapters    = $adapters
        DNSConfigurations = $dns
        CustomHostsLines  = $hostsLines
    }
}

# ==============================================================================
# LAYER L12: FORENSIC EVENT LOGS, WHEA HARDWARE ERRORS & BSOD MINIDUMPS
# ==============================================================================
$L12 = Invoke-SafeCollector -LayerId "L12" -LayerName "Forensic Event Logs, WHEA & BSOD Minidumps" -CollectorBlock {
    $since = (Get-Date).AddDays(-14)
    $wheaEvents = @(Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WHEA-Logger'; StartTime=$since} -MaxEvents 20 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, LevelDisplayName, @{N='Msg';E={($_.Message -replace '[\r\n]+',' ').Substring(0, [math]::Min(180, $_.Message.Length))}})

    if ($wheaEvents.Count -gt 0) {
        Add-Alert -Severity "CRITICAL" -Domain "L12-Forensics" -Title "$($wheaEvents.Count) WHEA Hardware Error Event(s) Detected in Last 14 Days" `
            -Evidence "Event IDs: $(($wheaEvents.Id | Select-Object -Unique) -join ', ')" `
            -Recommendation "Inspect CPU Curve Optimizer/Undervolt, RAM XMP stability, or PCIe/NVMe bus integrity immediately." -Tier "T2"
    }

    $kp41 = @(Get-WinEvent -FilterHashtable @{LogName='System'; Id=41; StartTime=$since} -MaxEvents 15 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id)

    $appCrashes = @(Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1002; StartTime=$since} -MaxEvents 25 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, @{N='Summary';E={($_.Message -replace '[\r\n]+',' ').Substring(0, [math]::Min(160, $_.Message.Length))}})

    $minidumps = @()
    if (Test-Path "$env:SystemRoot\Minidump") {
        $minidumps = @(Get-ChildItem "$env:SystemRoot\Minidump\*.dmp" -ErrorAction SilentlyContinue |
            Select-Object Name, LastWriteTime, @{N='SizeKB';E={[math]::Round($_.Length/1KB,1)}})
    }

    [PSCustomObject]@{
        WHEA_HardwareErrors = $wheaEvents
        KernelPower41Count  = $kp41.Count
        RecentAppCrashes    = $appCrashes
        MinidumpFiles       = $minidumps
    }
}

# ==============================================================================
# LAYER L13 & L14: THE SOFTWARE UNIVERSE (S1-S9) & WINGET UPGRADE LEDGER
# ==============================================================================
$L13 = Invoke-SafeCollector -LayerId "L13" -LayerName "Software Universe (Registry + Winget Upgrades)" -CollectorBlock {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $installedApps = @(Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Sort-Object DisplayName -Unique)

    [PSCustomObject]@{
        TotalInstalledCount = $installedApps.Count
        InstalledSoftware   = $installedApps
    }
}

# ==============================================================================
# LAYER L15: GAMING, ANTI-CHEAT, DIRECTX & TIMER CONFIG
# ==============================================================================
$L15 = Invoke-SafeCollector -LayerId "L15" -LayerName "Gaming Stack, Anti-Cheat & Shader Cache" -CollectorBlock {
    $acServices = @(Get-Service -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'vgk|vgc|EasyAntiCheat|BEService|faceit|ricochet' } |
        Select-Object Name, DisplayName, Status, StartType)

    $gameDvr = Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        AntiCheatServices = $acServices
        GameDVR_Enabled   = $gameDvr.GameDVR_Enabled
        FSE_Behavior      = $gameDvr.GameDVR_FSEBehaviorMode
    }
}

# ==============================================================================
# LAYER L16: SECURITY POSTURE, DEFENDER EXCLUSIONS & RESTORE POINTS
# ==============================================================================
$L16 = Invoke-SafeCollector -LayerId "L16" -LayerName "Security Posture, Defender & System Restore" -RequiresAdmin $true -CollectorBlock {
    $mpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $mpPref   = Get-MpPreference -ErrorAction SilentlyContinue
    $restorePoints = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
        Select-Object SequenceNumber, Description, CreationTime -Last 10)

    if ($mpPref.ExclusionPath -and $mpPref.ExclusionPath.Count -gt 0) {
        Add-Alert -Severity "IMPORTANT" -Domain "L16-Security" -Title "Windows Defender Path Exclusions Configured ($($mpPref.ExclusionPath.Count))" `
            -Evidence "Excluded Paths: $($mpPref.ExclusionPath -join ', ')" `
            -Recommendation "Verify that every Defender exclusion was intentionally created by you and not added by malware/activators." -Tier "T2"
    }

    if ($restorePoints.Count -eq 0 -and $IsAdmin) {
        Add-Alert -Severity "FYI" -Domain "L16-Recovery" -Title "Zero System Restore Points Found" `
            -Evidence "Get-ComputerRestorePoint returned 0 snapshots" `
            -Recommendation "Create a verified Restore Point before executing any T2/T3 system updates or driver changes." -Tier "T2"
    }

    [PSCustomObject]@{
        RealTimeProtection = $mpStatus.RealTimeProtectionEnabled
        TamperProtection   = $mpStatus.IsTamperProtected
        SignatureAgeDays   = $mpStatus.AntivirusSignatureAge
        ExclusionPaths     = $mpPref.ExclusionPath
        RestorePointsCount = $restorePoints.Count
        RecentRestorePts   = $restorePoints
    }
}

# ==============================================================================
# COMPILE THE MASTER MARKDOWN DOSSIER (دليل الجهاز الكامل.md)
# ==============================================================================
$TotalDurationSec = [math]::Round(((Get-Date) - $ScriptStartTime).TotalSeconds, 2)
$TriageColor = if ($ExpertAlerts | Where-Object { $_.Severity -eq "CRITICAL" }) { "RED (CRITICAL ATTENTION NEEDED)" }
               elseif ($ExpertAlerts | Where-Object { $_.Severity -eq "IMPORTANT" }) { "AMBER (OPTIMIZATION / FIXES NEEDED)" }
               else { "GREEN (HEALTHY BASELINE)" }

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# 📘 دليل الجهاز الكامل | NEXORA-WINDOWS Complete Device Guide")
[void]$md.AppendLine("> **تنبيه للذكاء الاصطناعي (AI Directive):** هذا الملف هو البصمة الهندسية الكاملة للجهاز (**16-Layer Complete Device Dossier**). إذا تم تزويدك ببرومبت **NEXORA-WINDOWS v20.0 APEX**، ادخل فوراً في وضع `[MODE: DOSSIER-READY]` وحلل البيانات أدناه مباشرة بدون طلب إعادة الفحص.")
[void]$md.AppendLine("")
[void]$md.AppendLine("## 0. بطاقة الهوية والتصنيف الفوري (Identity & Triage Stamp)")
[void]$md.AppendLine("| المؤشر | القيمة الموثقة `[OBSERVED]` |")
[void]$md.AppendLine("|---|---|")
[void]$md.AppendLine("| **اسم الجهاز (Hostname)** | `$($L01.Hostname)` |")
[void]$md.AppendLine("| **معرّف الفحص (Run ID)** | `$RunId` |")
[void]$md.AppendLine("| **تاريخ ووقت التوليد** | `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')` |")
[void]$md.AppendLine("| **مستوى الصلاحية (Elevation)** | `$(if($IsAdmin){'Administrator (Full Deep Visibility)'}else{'Standard User (Partial Elevation Holes)'})` |")
[void]$md.AppendLine("| **حالة الفرز الهندسي (Triage)** | **$TriageColor** |")
[void]$md.AppendLine("| **الزمن المستغرق للجمع** | `${TotalDurationSec}s` |")
[void]$md.AppendLine("")

[void]$md.AppendLine("## 🚨 التنبيهات الاستباقية المكتشفة تلقائياً (Automated Expert Alerts)")
if ($ExpertAlerts.Count -eq 0) {
    [void]$md.AppendLine("- `[OBSERVED]` لم يتم رصد تنبيهات حرجة أولية ضمن نطاق الفحص الحالي.")
} else {
    [void]$md.AppendLine("| الخطورة | المجال | التنبيه | الدليل `[OBSERVED]` | التوصية الهندسية | المستوى |")
    [void]$md.AppendLine("|---|---|---|---|---|---|")
    foreach ($a in $ExpertAlerts) {
        [void]$md.AppendLine("| **$($a.Severity)** | `$($a.Domain)` | $($a.Title) | $($a.Evidence) | $($a.Recommendation) | `$($a.Tier)` |")
    }
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 1. الطبقة L01: النظام، اللوحة الأم، والبايوس (Platform & UEFI)")
[void]$md.AppendLine("- **نظام التشغيل:** $($L01.OSCaption) | الإصدار: `$($L01.DisplayVersion)` | البناء: `$($L01.OSBuild)` (`$($L01.Architecture)`)")
[void]$md.AppendLine("- **تاريخ التثبيت:** `$($L01.InstallDate)` | **آخر إقلاع:** `$($L01.LastBootUpTime)` (مدة التشغيل: `$($L01.UptimeDays)` يوم)")
[void]$md.AppendLine("- **الجهاز واللوحة الأم:** `$($L01.Manufacturer)` - `$($L01.SystemModel)` | BaseBoard: `$($L01.BaseBoardVendor) $($L01.BaseBoardModel)`")
[void]$md.AppendLine("- **البايوس (BIOS/UEFI):** `$($L01.BIOSVendor)` | الإصدار: `$($L01.BIOSVersion)` | التاريخ: `$($L01.BIOSReleaseDate)`")
[void]$md.AppendLine("- **الأمان والإقلاع:** Secure Boot: `$($L01.SecureBoot)` | Fast Startup: `$($L01.FastStartup)`")
[void]$md.AppendLine("")

[void]$md.AppendLine("## 2. الطبقة L02 & L03: المعالج والذاكرة العشوائية (CPU & RAM Topology)")
[void]$md.AppendLine("- **المعالج (CPU):** `$($L02.Name)` | الأنوية الفيزيائية: `$($L02.PhysicalCores)` | المنطقية: `$($L02.LogicalProcessors)` | التردد الأقصى: `$($L02.MaxClockMHz) MHz`")
[void]$md.AppendLine("- **الكاش والـ Virtualization:** L2: `$($L02.L2CacheKB) KB` | L3: `$($L02.L3CacheKB) KB` | Firmware Virtualization: `$($L02.VirtualizationFirmwareOn)` | Hypervisor Active: `$($L02.HypervisorPresent)`")
[void]$md.AppendLine("- **الرام الكلي:** `$($L03.TotalRAM_GB) GB` (المتاح: `$($L03.FreeRAM_GB) GB` - المستخدم: `$($L03.UsedRAM_Percent)%`) | الوضع: `$($L03.ChannelEstimate)`")
[void]$md.AppendLine("")
[void]$md.AppendLine("### تفاصيل شرائح الرام (DIMM Slots)")
[void]$md.AppendLine("| المنفذ | الشركة | رقم القطعة | السعة | السرعة المصنعية | السرعة الحالية |")
[void]$md.AppendLine("|---|---|---|---|---|---|")
foreach ($d in $L03.DIMMs) {
    [void]$md.AppendLine("| `$($d.Slot)` | `$($d.Manufacturer)` | `$($d.PartNumber)` | `$($d.CapacityGB) GB` | `$($d.RatedSpeedMHz) MHz` | `$($d.RunningSpeedMHz) MHz` |")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 3. الطبقة L04: كروت الشاشة ومحرك العرض (GPU, HAGS, MPO & Displays)")
[void]$md.AppendLine("- **جدولة الكرت (HAGS):** `$($L04.HAGS)` | **حالة MPO:** `$($L04.MPO)` | **TdrDelay:** `$($L04.TdrDelay)`")
[void]$md.AppendLine("| الكرت الرسومي (GPU) | إصدار التعريف | تاريخ التعريف | الدقة الحالية | معدل التحديث (Hz) | الحالة |")
[void]$md.AppendLine("|---|---|---|---|---|---|")
foreach ($g in $L04.GPUs) {
    [void]$md.AppendLine("| `$($g.Name)` | `$($g.DriverVersion)` | `$($g.DriverDate)` | `$($g.Resolution)` | `$($g.CurrentRefreshRate) Hz (Max: $($g.MaxRefreshRate) Hz)` | `$($g.Status)` |")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 4. الطبقة L05: الأقراص الفيزيائية، صحة SMART، والتقسيمات (Storage & SMART)")
[void]$md.AppendLine("### الأقراص الفيزيائية (Physical Disks)")
[void]$md.AppendLine("| الموديل | النوع | الناقل | السعة | الصحة | الحرارة | التآكل (Wear) | أخطاء قراءة/كتابة | ساعات العمل |")
[void]$md.AppendLine("|---|---|---|---|---|---|---|---|---|")
foreach ($d in $L05.PhysicalDisks) {
    [void]$md.AppendLine("| `$($d.FriendlyName)` | `$($d.MediaType)` | `$($d.BusType)` | `$($d.SizeGB) GB` | **$($d.HealthStatus)** | `$($d.TemperatureC) C` | `$($d.WearPercent)%` | `R:$($d.ReadErrorsUncorrected) / W:$($d.WriteErrorsUncorrected)` | `$($d.PowerOnHours)` |")
}
[void]$md.AppendLine("")
[void]$md.AppendLine("### الأقسام المنطقية (Volumes)")
[void]$md.AppendLine("| الحرف | التسمية | النظام | السعة الكلية | المساحة الحرة | النسبة الحرة | الحالة |")
[void]$md.AppendLine("|---|---|---|---|---|---|---|")
foreach ($v in $L05.Volumes) {
    [void]$md.AppendLine("| `$($v.DriveLetter):` | `$($v.Label)` | `$($v.FileSystem)` | `$($v.SizeGB) GB` | `$($v.FreeGB) GB` | **$($v.FreePercent)%** | `$($v.HealthStatus)` |")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 5. الطبقة L06 & L07: الطاقة، التعريفات، والأجهزة المتعطلة")
[void]$md.AppendLine("- **خطة الطاقة النشطة:** `$($L06.ActivePowerPlan)`")
[void]$md.AppendLine("- **البطارية:** `$($L06.BatteryName)` (الشحن: `$($L06.BatteryChargeRemaining)`)")
[void]$md.AppendLine("- **الأجهزة التي بها كود خطأ (PnP Problem Devices):** `$($L07.ProblemDevices.Count)`")
foreach ($p in $L07.ProblemDevices) {
    [void]$md.AppendLine("  - ⚠️ `$($p.Name)` | Class: `$($p.PNPClass)` | ErrorCode: `$($p.ConfigManagerErrorCode)` | ID: `$($p.DeviceID)`")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 6. الطبقة L08 & L09: الخدمات، أعلى العمليات استهلاكاً، وبرامج بدء التشغيل")
[void]$md.AppendLine("### أعلى العمليات استهلاكاً للذاكرة (Top Processes)")
[void]$md.AppendLine("| العملية | PID | استهلاك الرام (MB) | زمن المعالج (s) | المسار |")
[void]$md.AppendLine("|---|---|---|---|---|")
foreach ($pr in ($L08.TopProcessesByRAM | Select-Object -First 15)) {
    [void]$md.AppendLine("| `$($pr.Name)` | `$($pr.Id)` | `$($pr.RAM_MB) MB` | `$($pr.CPU_Sec)` | `$($pr.Path)` |")
}
[void]$md.AppendLine("")
[void]$md.AppendLine("### برامج بدء التشغيل (Startup Commands)")
foreach ($st in $L09.StartupCommands) {
    [void]$md.AppendLine("- **`$($st.Name)`**: `$($st.Command)` *(الموقع: `$($st.Location)`)*")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 7. الطبقة L10 & L11: الرجستري التشخيصي والشبكة")
[void]$md.AppendLine("- **إعادة التشغيل المعلقة (Reboot Pending):** CBS=`$($L10.CBS_RebootPending)` | WindowsUpdate=`$($L10.WU_RebootRequired)`")
[void]$md.AppendLine("- **إعدادات Multimedia/Gaming Scheduler:** SystemResponsiveness=`$($L10.SystemResponsiveness)` | NetworkThrottlingIndex=`$($L10.NetworkThrottlingIndex)` | Games GPU Priority=`$($L10.Games_GPUPriority)` | Priority=`$($L10.Games_Priority)`")
[void]$md.AppendLine("- **كروت الشبكة النشطة:**")
foreach ($na in $L11.ActiveAdapters) {
    [void]$md.AppendLine("  - `$($na.Name)` (`$($na.InterfaceDescription)`) | السرعة: `$($na.LinkSpeed)`")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 8. الطبقة L12: السجل الجنائي، أخطاء الهاردوير WHEA، وانهيارات البرامج")
[void]$md.AppendLine("- **عدد انقطاعات الطاقة المفاجئة (Kernel-Power 41 آخر 14 يوماً):** `$($L12.KernelPower41Count)`")
[void]$md.AppendLine("- **عدد أخطاء الهاردوير (WHEA-Logger آخر 14 يوماً):** `$($L12.WHEA_HardwareErrors.Count)`")
[void]$md.AppendLine("- **عدد ملفات الشاشة الزرقاء (Minidumps):** `$($L12.MinidumpFiles.Count)`")
foreach ($mp in $L12.MinidumpFiles) {
    [void]$md.AppendLine("  - 💥 `$($mp.Name)` | التاريخ: `$($mp.LastWriteTime)` | الحجم: `$($mp.SizeKB) KB`")
}
[void]$md.AppendLine("- **أحدث انهيارات التطبيقات والألعاب (Event 1000/1002):**")
foreach ($ac in ($L12.RecentAppCrashes | Select-Object -First 10)) {
    [void]$md.AppendLine("  - `[$($ac.TimeCreated)]` Event `$($ac.Id)`: $($ac.Summary)")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 9. الطبقة L13: جرد البرامج المثبتة (Software Universe Inventory - $($L13.TotalInstalledCount) App)")
[void]$md.AppendLine("| البرنامج (DisplayName) | الإصدار (Version) | الناشر (Publisher) | تاريخ التثبيت |")
[void]$md.AppendLine("|---|---|---|---|")
foreach ($app in ($L13.InstalledSoftware | Select-Object -First 120)) {
    [void]$md.AppendLine("| $($app.DisplayName) | `$($app.DisplayVersion)` | $($app.Publisher) | `$($app.InstallDate)` |")
}
[void]$md.AppendLine("")

[void]$md.AppendLine("## 10. الطبقة L15 & L16: الألعاب، الحماية، ونقاط الاستعادة")
[void]$md.AppendLine("- **Windows Defender Real-Time Protection:** `$($L16.RealTimeProtection)` | **Tamper Protection:** `$($L16.TamperProtection)`")
[void]$md.AppendLine("- **مسارات الاستثناءات في Defender:** `$(if($L16.ExclusionPaths){$L16.ExclusionPaths -join '; '}else{'None (Clean)'})`")
[void]$md.AppendLine("- **عدد نقاط الاستعادة المتوفرة (System Restore Points):** `$($L16.RestorePointsCount)`")
[void]$md.AppendLine("")

[void]$md.AppendLine("## 11. إيصال الاكتمال وسجل التغطية (Coverage Ledger & Completion Receipt)")
[void]$md.AppendLine("| الطبقة | الوصف | الحالة | الزمن (ms) | ملاحظات |")
[void]$md.AppendLine("|---|---|---|---|---|")
foreach ($c in $CoverageLedger) {
    [void]$md.AppendLine("| `$($c.Layer)` | $($c.Name) | **$($c.Status)** | `$($c.DurationMs)` | $($c.Notes) |")
}

$md.ToString() | Set-Content -LiteralPath $OutputFilePath -Encoding UTF8

if ($IncludeJsonExport) {
    [PSCustomObject]@{
        Meta           = @{ RunId = $RunId; GeneratedAt = (Get-Date).ToString("o"); Hostname = $HostName; IsAdmin = $IsAdmin; Triage = $TriageColor }
        ExpertAlerts   = $ExpertAlerts
        CoverageLedger = $CoverageLedger
        Layers         = $FullTelemetry
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $JsonFilePath -Encoding UTF8
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "[SUCCESS] تم توليد «دليل الجهاز الكامل» بنجاح!" -ForegroundColor Green
Write-Host "المسار: $OutputFilePath" -ForegroundColor Yellow
Write-Host "===============================================================================" -ForegroundColor Green

if ($OpenWhenDone) {
    Start-Process "explorer.exe" -ArgumentList "/select,`"$OutputFilePath`""
}
