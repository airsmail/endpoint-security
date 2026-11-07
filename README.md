# 🛡️ Zero-Trust Endpoint Security & MDM

## 📌 Overview
Sanitized, simplified examples based on endpoint security configurations I have worked with, built around **Microsoft Intune**, **Microsoft Entra ID** and **Windows LAPS**, aligned with **ISO 27001** controls. The JSON files are readable representations of the policy logic, not direct Microsoft Graph exports, and all identifiers are placeholders. Review and test everything in a lab tenant before using it.

## 🏗️ Architecture & Core Components
* **Identity & Access:** Microsoft Entra ID with Conditional Access.
* **Device Management:** Microsoft Intune (MDM for corporate devices, MAM for BYOD).
* **Local admin passwords:** Windows LAPS, backed up to Entra ID. Configured through an Intune endpoint security policy, which is not included in this repo.
* **Disk encryption:** BitLocker (XTS-AES 256-bit) with recovery keys escrowed to Entra ID. Configured through an Intune endpoint security policy, which is not included in this repo.

## 📂 Contents
| File | Purpose |
| --- | --- |
| `conditional_access_policy.json` | Require MFA and a compliant device for all cloud apps, starting in report-only mode |
| `mam_byod_policy.json` | App protection for BYOD iOS devices: PIN, restricted copy/paste, no backup, minimum OS version |
| `mam_target_apps.json` | Apps the MAM policy applies to (Outlook, Teams) |
| `asr_defender_policy.json` | Defender ASR rules: Office macro abuse, Office child processes and code injection, LSASS credential theft, email executables, untrusted USB processes |
| `Detect-EndpointHardening.ps1` | Intune Remediations detection: checks BitLocker, SMBv1 and LAPS configuration |
| `Remediate-EndpointHardening.ps1` | Intune Remediations remediation: disables the SMBv1 server protocol |

## 🔐 Security Posture
1. **Lateral movement:** Windows LAPS gives every device a unique, rotating local administrator password, so one stolen credential cannot be reused across devices. Disabling SMBv1 removes a legacy attack path.
2. **Compliance signal:** The detection script returns exit code 1 when a device deviates, and the result shows up in the Intune Remediations report (formerly Proactive Remediations). Device compliance itself is evaluated by Intune compliance policies, which Conditional Access uses to gate access.
3. **Safe rollout:** Conditional Access starts in report-only mode, ASR rules start in audit mode, and every change is tested on a pilot group first.

## 🛡️ Attack Surface Reduction (ASR)
`asr_defender_policy.json` is a simplified representation of an Intune endpoint security ASR policy. In Intune, configure it under *Endpoint security > Attack surface reduction*.

**Rules covered:**
* **Office macro abuse:** Blocks Win32 API calls from Office macros, Office applications creating child processes, and code injection into other processes. This reduces exposure to macro-based malware delivery.
* **LSASS protection:** Blocks credential stealing from the Local Security Authority Subsystem, which stops common credential dumping tools.
* **Email executables:** Blocks executable content from email clients and webmail.
* **USB execution control:** Blocks untrusted and unsigned processes that run from removable media.

## ⚖️ Conditional Access (Entra ID)
`conditional_access_policy.json` describes the core Zero-Trust identity policy.

**Policy mechanics:**
* **MFA and device compliance:** Access to all cloud apps requires both multi-factor authentication and a device marked "Compliant" by Intune.
* **Break-glass exclusion:** An emergency access group is excluded to prevent tenant-wide lockouts. Replace the placeholder GUID with your group's object ID.
* **Report-only first:** The policy starts in report-only mode. Review the sign-in logs, then switch the state to `enabled`.
* **Enrollment:** Consider excluding the Microsoft Intune Enrollment app, otherwise new devices cannot enroll.

**Deploy with Microsoft Graph PowerShell (lab tenant first):**
```powershell
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Application.Read.All"

$body = Get-Content -Raw -Path .\conditional_access_policy.json
Invoke-MgGraphRequest -Method POST `
  -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" `
  -Body $body -ContentType "application/json"
```
Use an account with the Conditional Access Administrator role rather than Global Administrator.

## 📱 Mobile Application Management (MAM) & BYOD
`mam_byod_policy.json` demonstrates app-level data protection for unmanaged personal iOS devices.

**Key controls:**
* **Containerization:** Copy and paste from managed apps (Outlook, Teams) to personal apps is restricted.
* **Save-As restrictions:** Corporate files can only be saved to SharePoint and OneDrive for Business, not to local storage or personal cloud drives.
* **Backup blocked, PIN enforced:** No simple PINs, and the app data is wiped after too many failed PIN attempts.
* **Selective wipe:** Intune can remove only corporate data from a device, for example at offboarding. This is a separate Intune action, not part of this policy file.

**Deploy with Microsoft Graph PowerShell (lab tenant first):**
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"

$policy = Invoke-MgGraphRequest -Method POST `
  -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/iosManagedAppProtections" `
  -Body (Get-Content -Raw -Path .\mam_byod_policy.json) -ContentType "application/json"

Invoke-MgGraphRequest -Method POST `
  -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/iosManagedAppProtections/$($policy.id)/targetApps" `
  -Body (Get-Content -Raw -Path .\mam_target_apps.json) -ContentType "application/json"
```
Assign the policy to a user group afterwards in the Intune admin center.

## ⚠️ Notes & Limitations
* The scripts only check BitLocker and LAPS. Those are enforced by Intune policies, and only SMBv1 is remediated by script.
* The LAPS check verifies that configuration exists, not that a password was actually backed up to Entra ID.
* The MAM example covers iOS only. Android needs a separate policy.
* Intune Remediations requires the appropriate licensing.
* The deployment snippets are provided as a starting point, test them in a lab tenant first.
