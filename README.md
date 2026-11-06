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
