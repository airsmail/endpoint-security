# 🛡️ Zero-Trust Endpoint Security & MDM

## 📌 Module Overview
This module contains the endpoint security configurations, compliance scripts, and policies deployed via **Microsoft Intune (Endpoint Manager)**. It is designed to enforce a strict Zero-Trust architecture across all corporate and homelab endpoints, aligning with **ISO 27001** information security standards.

## 🏗️ Architecture & Core Components
* **Identity & Access:** Microsoft Entra ID (Azure AD) with Conditional Access.
* **Device Management:** Microsoft Intune (MDM/MAM).
* **Privileged Access Management:** Windows LAPS (Local Administrator Password Solution) integrated with Entra ID.
* **Data at Rest Protection:** Silent BitLocker Encryption (XTS-AES 256-bit) with cloud-backed recovery keys.

## 🔐 Security Posture (Why This Matters)
1. **Lateral Movement Prevention:** By dynamically rotating the local administrator passwords via **Windows LAPS**, pass-the-hash attacks and lateral network movements are heavily mitigated.
2. **Silent Compliance:** The included PowerShell scripts (`Invoke-EndpointHardening.ps1`) run as Intune Proactive Remediations. They silently disable legacy protocols (like SMBv1) and verify BitLocker health without disrupting the end-user workflow.
3. **Automated Remediation:** Non-compliant devices are automatically flagged in Intune, triggering Conditional Access policies that block access to critical corporate resources until the endpoint is secure.

## 🛡️ Attack Surface Reduction (ASR) & Ransomware Mitigation
Included in this repository is the `asr_defender_policy.json` payload, demonstrating an enterprise Intune Graph API export for Microsoft Defender ASR rules.

**Key Mitigations Enforced:**
* **LSASS Protection:** Blocks credential dumping from the Local Security Authority Subsystem, effectively preventing Pass-the-Hash attacks.
* **Macro & Office Security:** Prevents Office applications from creating child processes or injecting code into other processes (stopping Emotet/Trickbot style vectors).
* **USB Execution Control:** Blocks untrusted and unsigned processes from executing directly from removable storage media.
* **Telemetry & Analytics:** Enforces continuous monitoring of all file activity across the endpoint fleet, feeding telemetry directly into Defender XDR.

## ⚖️ Conditional Access (Entra ID)
The `conditional_access_policy.json` file contains the Microsoft Graph API export for the core Zero-Trust identity perimeter.

**Policy Mechanics:**
* **Strict Device Compliance:** Blocks access to all corporate cloud applications (Office 365, Teams, SharePoint) unless the device is marked as "Compliant" by Microsoft Intune.
* **MFA Enforcement:** Demands Multi-Factor Authentication for all sign-ins, serving as a secondary perimeter if compliance checks face latency.
* **Break-Glass Exclusion:** Includes standard enterprise exclusions for emergency access accounts to prevent tenant-wide lockouts.

### 🚀 How to Deploy / Import Policies
These JSON configurations are raw Microsoft Graph API payloads. You can import them directly into your own Entra ID and Intune tenant using standard enterprise automation tools:

**Option 1: PowerShell (Microsoft Graph SDK)**
The fastest way to deploy these policies programmatically is via the Microsoft Graph PowerShell module.

```powershell
# Connect to your tenant with required scopes
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess"

# Example: Deploying the Conditional Access Policy
$policyJson = Get-Content -Raw -Path .\conditional_access_policy.json | ConvertFrom-Json
New-MgIdentityConditionalAccessPolicy -BodyParameter $policyJson
```

**Option 2: Microsoft Graph Explorer**
For manual testing and validation without PowerShell:
1. Navigate to [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer).
2. Sign in with Global Administrator or Intune Administrator privileges.
3. Change the HTTP method to `POST`.
4. Paste the contents of the `.json` file into the **Request body**.
5. Run the query against the corresponding endpoint (e.g., `https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies`).

## 📱 Mobile Application Management (MAM) & BYOD
The `mam_byod_policy.json` file demonstrates a Data Loss Prevention (DLP) containerization approach for unmanaged personal devices (BYOD).

**Key DLP Controls:**
* **Data Containerization:** Prevents copying/pasting corporate data from managed apps (Outlook, Teams) to personal apps (WhatsApp, Notes).
* **Save-As Restrictions:** Blocks saving corporate attachments to local device storage or personal cloud drives (iCloud/Google Drive).
* **Selective Wipe:** Allows IT to wipe only corporate data upon employee offboarding, leaving personal photos and apps untouched.

### 🚀 How to Deploy / Import MAM Policies
This payload targets the Intune App Protection endpoints. You can import it using the Microsoft Graph PowerShell SDK:

```powershell
# Connect with Intune App Management scopes
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"

# Deploy the iOS MAM Policy
$mamJson = Get-Content -Raw -Path .\mam_byod_policy.json | ConvertFrom-Json
New-MgDeviceAppManagementIosManagedAppProtection -BodyParameter $mamJson
```

*Note: For manual API testing, POST this JSON payload to `https://graph.microsoft.com/v1.0/deviceAppManagement/iosManagedAppProtections` using Microsoft Graph Explorer.*
