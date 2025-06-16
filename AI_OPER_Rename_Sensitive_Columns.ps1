<#
.SYNOPSIS
Renames sensitive or personally identifiable columns in a CSV dataset to anonymized or generic names.

.DESCRIPTION
This script scans column headers in an input CSV file and replaces known sensitive field names (e.g., Email, Phone, Name, Address) with standardized anonymized labels like `Field1_Email`, `Field2_Name`, etc. This process is useful for pseudonymization or anonymization before using data in AI/LLM pipelines.

.NOTES
Author: Ivan Garkusha
Filename: AI_OPER_Rename_Sensitive_Columns.ps1
Version: 1.0

.REQUIREMENTS
- PowerShell 5.1+
- Input CSV with headers
- Write permission to destination directory

.INPUTS
- CSV file path (e.g., "data.csv")

.OUTPUTS
- Processed CSV with renamed headers (e.g., "data_renamed.csv")

.EXAMPLE
.\AI_OPER_Rename_Sensitive_Columns.ps1 -InputPath "export.csv" -OutputPath "clean_export.csv"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$InputPath,

    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define mapping of sensitive fields to generic names
$fieldMap = @{
    "email"        = "Field1_Email"
    "e-mail"       = "Field1_Email"
    "name"         = "Field2_Name"
    "fullname"     = "Field2_Name"
    "username"     = "Field3_Username"
    "login"        = "Field3_Username"
    "phone"        = "Field4_Phone"
    "phonenumber"  = "Field4_Phone"
    "address"      = "Field5_Address"
    "location"     = "Field5_Address"
    "dob"          = "Field6_DOB"
    "birthdate"    = "Field6_DOB"
}

Write-Host "Loading CSV from $InputPath..."
$data = Import-Csv -Path $InputPath

if (-not $data) {
    Write-Warning "No data found in CSV!"
    exit
}

# Get current headers and transform them
$newHeaders = @()
foreach ($col in $data[0].PSObject.Properties.Name) {
    $normalized = $col.Trim().ToLower()
    if ($fieldMap.ContainsKey($normalized)) {
        $newHeaders += $fieldMap[$normalized]
    } else {
        $newHeaders += $col
    }
}

# Apply new headers
$renamedData = foreach ($row in $data) {
    $newRow = [ordered]@{}
    for ($i = 0; $i -lt $data[0].PSObject.Properties.Count; $i++) {
        $newRow[$newHeaders[$i]] = $row.($data[0].PSObject.Properties[$i].Name)
    }
    [pscustomobject]$newRow
}

# Export to output file
$renamedData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Renamed CSV saved to $OutputPath"
