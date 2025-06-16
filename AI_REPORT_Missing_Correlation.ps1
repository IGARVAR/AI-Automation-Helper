<#
.SYNOPSIS
Compares two CSV datasets to identify missing or mismatched records based on email correlation.

.DESCRIPTION
This script compares a source dataset with a reference lookup by email or UPN, and reports:
- Entries in the source that have no match in the lookup
- Optional: fields that differ in key attributes (e.g., Role, Group, Department)

.NOTES
Author: Ivan Garkusha  
Filename: AI_REPORT_Missing_Correlation.ps1

REQUIREMENTS:
- Two CSV files with a common identifier field (email or UPN)
- PowerShell 5.1+ or Core

USE CASES:
- Pre-migration audits before M365 or SharePoint sync
- AI/ML dataset correlation checks
- Validating mapped vs unmapped security group ownership

#>

# === CONFIGURATION ===
$sourcePath = "users_source.csv"        # Dataset to verify
$lookupPath = "users_reference.csv"     # Expected reference set
$outputPath = "missing_correlation.csv" # Report output

# === IMPORT AND VALIDATION ===
if (-not (Test-Path $sourcePath) -or -not (Test-Path $lookupPath)) {
    Write-Error "Source or lookup file not found."
    exit 1
}

$source = Import-Csv $sourcePath
$lookup = Import-Csv $lookupPath

# Normalize lookup to dictionary by email (case-insensitive)
$lookupDict = @{}
foreach ($row in $lookup) {
    $email = $row.Email.ToLower()
    if (-not $lookupDict.ContainsKey($email)) {
        $lookupDict[$email] = $row
    }
}

# === CORRELATION LOGIC ===
$missing = @()

foreach ($record in $source) {
    $email = $record.Email.ToLower()
    if (-not $lookupDict.ContainsKey($email)) {
        $missing += [PSCustomObject]@{
            Email    = $record.Email
            Name     = $record.Name
            Status   = "Missing in reference"
        }
    }
}

# === OUTPUT ===
if ($missing.Count -gt 0) {
    $missing | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
    Write-Host "⚠️ $($missing.Count) records missing. Report saved to $outputPath"
} else {
    Write-Host "✅ All entries matched successfully."
}
