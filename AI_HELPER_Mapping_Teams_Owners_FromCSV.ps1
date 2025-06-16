<#
.SYNOPSIS
Parses and normalizes a CSV of Microsoft Teams and their designated owners.

.DESCRIPTION
This script reads a CSV file containing 'TeamName' and 'OwnerUPN' columns, validates and groups them into a structured mapping.
Used to prepare data for automated Microsoft Teams creation, access governance workflows, or ownership audits.

.NOTES
Author: Ivan Garkusha
Filename: AI_HELPER_Mapping_Teams_Owners_FromCSV.ps1

REQUIREMENTS:
- A properly structured CSV with at least two columns: TeamName, OwnerUPN
- PowerShell 5.1+ or Core

USE CASES:
- Preparing GitOps-based inputs for Teams + AD provisioning
- Generating JSON-based team-to-owner ownership policies
- Validating owner fields before provisioning

CSV STRUCTURE:
TeamName,OwnerUPN
Marketing Team,alice@domain.com
Marketing Team,bob@domain.com
Engineering Team,charlie@domain.com

#>

# Input path
$CsvPath = "teams_owners_input.csv"   # Replace with actual file path

# Output path
$JsonOutputPath = "teams_owners_mapping.json"

# Validate CSV exists
if (-not (Test-Path $CsvPath)) {
    Write-Error "Input CSV file not found at $CsvPath"
    exit 1
}

# Import CSV and normalize data
$records = Import-Csv -Path $CsvPath | Where-Object {
    $_.TeamName -and $_.OwnerUPN
}

if (-not $records) {
    Write-Warning "No valid records found."
    exit 0
}

# Group by Team
$grouped = $records | Group-Object TeamName

# Build structured object
$mapping = foreach ($group in $grouped) {
    [PSCustomObject]@{
        TeamName  = $group.Name
        OwnersUPN = $group.Group.OwnerUPN | Sort-Object -Unique
    }
}

# Export to JSON
$mapping | ConvertTo-Json -Depth 3 | Out-File -FilePath $JsonOutputPath -Encoding UTF8

Write-Host "✔ Team-to-Owner mapping exported to $JsonOutputPath"
