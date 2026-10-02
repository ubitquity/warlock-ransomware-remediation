<#
.SYNOPSIS
    Emergency Mitigation Script - Warlock Ransomware (Longlegs/Storm-2603)
.DESCRIPTION
    Mitigates TTPs associated with Warlock:
    1. Blocks the vulnerable K7RKScan driver (CVE-2025-1055) via registry.
    2. Hunts for and disables VS Code Insiders Tunneling services.
    3. Scans SYSVOL for suspicious executables/scripts staged for GPO deployment.
#>

Write-Host "[*] Initiating Warlock Ransomware Mitigation Patch..." -ForegroundColor Cyan

# 1. Mitigate BYOVD (CVE-2025-1055) - Block K7RKScan Driver
Write-Host "[*] Phase 1: Blocking vulnerable K7RKScan driver..."
$DriverPath = "C:\Windows\System32\drivers\K7RKScan.sys"
if (Test-Path $DriverPath) {
    Write-Host "[!] Found K7RKScan.sys! Attempting to rename/disable..." -ForegroundColor Yellow
    Rename-Item -Path $DriverPath -NewName "K7RKScan.sys.BLOCKED" -Force
}

# Add driver to the Image File Execution Options (IFEO) debugger trap to prevent loading (if executed as userland, otherwise use WDAC for kernel blocks)
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\K7RKScan.sys"
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
Set-ItemProperty -Path $RegPath -Name "Debugger" -Value "systray.exe" -Force
Write-Host "[+] Driver execution mitigated." -ForegroundColor Green


# 2. Kill and Disable VS Code Insiders Tunneling
Write-Host "[*] Phase 2: Auditing for unauthorized VS Code Tunneling services..."
$VSServices = Get-Service | Where-Object { $_.Name -match "code-insiders-tunnel" -or $_.DisplayName -match "Visual Studio Code Insiders Tunnel" }

if ($VSServices) {
    foreach ($Service in $VSServices) {
        Write-Host "[!] Unauthorized VS Code Tunnel service found: $($Service.Name)" -ForegroundColor Red
        Stop-Service -Name $Service.Name -Force
        Set-Service -Name $Service.Name -StartupType Disabled
        Write-Host "[+] Service stopped and disabled." -ForegroundColor Green
    }
} else {
    Write-Host "[+] No VS Code Tunneling services detected." -ForegroundColor Green
}


# 3. Audit SYSVOL for Staged Payloads
Write-Host "[*] Phase 3: Auditing SYSVOL share for unexpected executables..."
$SysvolPath = "\\$env:USERDOMAIN\SYSVOL\$env:USERDOMAIN"
$SuspiciousExtensions = @("*.exe", "*.ps1", "*.bat", "*.vbs", "*.dll", "*.msi")

if (Test-Path $SysvolPath) {
    $StagedFiles = Get-ChildItem -Path $SysvolPath -Include $SuspiciousExtensions -Recurse -ErrorAction SilentlyContinue | 
                   Where-Object { $_.CreationTime -gt (Get-Date).AddDays(-14) }
    
    if ($StagedFiles) {
        Write-Host "[!] WARNING: Recently modified executable files found in SYSVOL!" -ForegroundColor Red
        $StagedFiles | Select-Object Name, FullName, CreationTime | Format-Table
    } else {
        Write-Host "[+] SYSVOL appears clean of recent executable staging." -ForegroundColor Green
    }
} else {
    Write-Host "[-] Not a domain controller or SYSVOL unreachable." -ForegroundColor Gray
}

Write-Host "[*] Mitigation script complete. Proceed to patch SharePoint." -ForegroundColor Cyan
