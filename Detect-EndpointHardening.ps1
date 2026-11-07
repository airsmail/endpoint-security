<#
.SYNOPSIS
    Detection script for Intune Remediations: BitLocker, SMBv1 and Windows LAPS checks.
.DESCRIPTION
    Exit 0 = compliant, Exit 1 = non-compliant (triggers the remediation script).
    The summary is written to stdout so it appears in the Intune Remediations report.
#>

$issues = @()

# 1. BitLocker (OS drive)
try {
    $osDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ($osDrive.VolumeStatus -ne 'FullyEncrypted') {
        $issues += "BitLocker not fully encrypted (status: $($osDrive.VolumeStatus))"
    }
} catch {
    $issues += "BitLocker status could not be read: $($_.Exception.Message)"
}

# 2. SMBv1 server protocol
try {
    $smb1 = (Get-SmbServerConfiguration -ErrorAction Stop).EnableSMB1Protocol
    if ($smb1 -eq $true) {
        $issues += "SMBv1 server protocol is enabled"
    }
} catch {
    $issues += "SMBv1 status could not be read: $($_.Exception.Message)"
}

# 3. Windows LAPS configuration present (local config or policy key)
$lapsConfigKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\Config"
$lapsPolicyKey = "HKLM:\SOFTWARE\Microsoft\Policies\LAPS"
if (-not (Test-Path $lapsConfigKey) -and -not (Test-Path $lapsPolicyKey)) {
    $issues += "Windows LAPS is not configured"
}

if ($issues.Count -gt 0) {
    Write-Output ("NON-COMPLIANT: " + ($issues -join "; "))
    exit 1
}

Write-Output "COMPLIANT: BitLocker, SMBv1 and LAPS checks passed"
exit 0
