# Warlock Ransomware (ToolShell) Incident Response & Mitigation

This repository provides an emergency mitigation script and incident response checklist for defending against the **Warlock ransomware** group (also tracked as Longlegs and Storm-2603). 

This threat actor leverages a chain of zero-day vulnerabilities in Microsoft SharePoint (known as "ToolShell") for initial access, bypasses EDR/AV using a Bring Your Own Vulnerable Driver (BYOVD) attack, and uses Visual Studio Code tunneling for persistent remote access. 

## 🚨 Threat Profile

* **Threat Actors:** Warlock / Longlegs / Storm-2603
* **Initial Access Vectors:** SharePoint "ToolShell" Vulnerabilities (CVE-2025-49704, CVE-2025-49706, CVE-2025-53770, and CVE-2025-53771).
* **Defense Evasion:** BYOVD technique using a vulnerable signed K7RKScan driver (CVE-2025-1055) to disable AV/EDR on endpoints.
* **Lateral Movement:** Active Directory enumeration via NetExec; ransomware payload staged and deployed via domain SYSVOL shares.
* **Persistence:** Visual Studio Code Insiders installed as a service to enable remote tunneling.

## 🛠️️ Script Capabilities (`Invoke-WarlockMitigation.ps1`)

The included PowerShell script performs the following automated mitigation actions on the host/domain controller:

1. **Driver Blocking:** Identifies and disables the vulnerable `K7RKScan.sys` driver to prevent the execution of the threat actor's EDR-killing tool.
2. **Persistence Eradication:** Scans the host for unauthorized Visual Studio Code Insiders Tunneling services, forcing them to stop and disabling their startup status.
3. **SYSVOL Auditing:** Scans the domain's `SYSVOL` share for recently staged executables, scripts, or MSIs (a known tactic for deploying the Warlock payload via GPO).

## 🚀 Usage

Run the script from an elevated PowerShell prompt (Run as Administrator). If auditing SYSVOL, the script should be run by an account with Domain Admin privileges or read-access to the SYSVOL share.

```powershell
# Bypass execution policy for the current session and run the script
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Invoke-WarlockMitigation.ps1
