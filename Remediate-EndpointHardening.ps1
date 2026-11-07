<#
.SYNOPSIS
    Remediation script for Intune Remediations: disables the SMBv1 server protocol.
.DESCRIPTION
    BitLocker and Windows LAPS are enforced by Intune endpoint security policies,
    so this script only fixes SMBv1.
#>

try {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction Stop
    Write-Output "SMBv1 server protocol disabled"
    exit 0
} catch {
    Write-Output "Remediation failed: $($_.Exception.Message)"
    exit 1
}
