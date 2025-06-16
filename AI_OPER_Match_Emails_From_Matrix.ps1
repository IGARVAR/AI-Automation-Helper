<#
.SYNOPSIS
Matches user emails from one dataset to another and extracts mapped values.

.DESCRIPTION
This script performs a correlation between two CSV files based on email addresses or UPNs.
It is typically used to enrich datasets with role/group/team information prior to analysis or migration.

.NOTES
Author: Ivan Garkusha
Filename: AI_OPER_Match_Emails_From_Matrix.ps1

REQUIREMENTS:
- PowerShell 5.1 or Core
- Input CSVs must contain "Email" (primary) and "Matrix" (reference) columns

USE CASES:
- Data mapping for AI/LLM pipelines
- Dataset preparation for identity correlation
- Enrichment before RBAC transformation

#>

# === CONFIGURATION ===
$sourcePath = "C:\Data\input_users.csv"         # Dataset to enrich
$matrixPath = "C:\Data\role_matrix.csv"         # Reference lookup table
$outputPath = "C:\Data\matched_output.csv"      # Resulting enriched output

# === LOAD DATA ===
$source = Import-Csv -Path $sourcePath
$matrix = Import-Csv -Path $matrixPath

# === INDEX REFERENCE TABLE ===
$matrixLookup = @{}
foreach ($entry in $matrix) {
    $key = $entry.Email.Trim().ToLower()
    if (-not $matrixLookup.ContainsKey($key)) {
        $matrixLookup[$key] = $entry
    }
}

# === MATCHING LOGIC ===
$results = @()

foreach ($row in $source) {
    $email = $row.Email.Trim().ToLower()

    if ($matrixLookup.ContainsKey($email)) {
        $matched = $matrixLookup[$email]

        # Combine both row and matched fields
        $result = [PSCustomObject]@{
            Email           = $email
            Name            = $row.Name
            Department      = $row.Department
            MatchedRole     = $matched.Role
            MatchedGroup    = $matched.GroupName
        }
        $results += $result
    }
    else {
        $results += [PSCustomObject]@{
            Email           = $email
            Name            = $row.Name
            Department      = $row.Department
            MatchedRole     = "[NOT FOUND]"
            MatchedGroup    = "[NOT FOUND]"
        }
    }
}

# === EXPORT RESULTS ===
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "✅ Matching completed. Output saved to: $outputPath" -ForegroundColor Green
