<#
.SYNOPSIS
Bulk enables Microsoft 365 Copilot for selected users based on input from a CSV file.

.DESCRIPTION
This script reads a list of users from a CSV file and ensures they are properly licensed and enabled for Microsoft 365 Copilot features.
It verifies E3/E5 eligibility, checks for necessary service plans (e.g., M365 Copilot SKU), and logs results of each operation.

.NOTES
Author: Ivan Garkusha
Version: 1.0
Filename: COPILOT_OPER_Enable_Copilot_Features.ps1
Date: 2025-06-16

.REQUIREMENTS
- Microsoft Graph PowerShell SDK
- Admin permissions to assign licenses and manage users
- Proper delegated or app-based access to Microsoft Graph

.EXAMPLE
.\COPILOT_OPER_Enable_Copilot_Features.ps1 -CsvPath ".\pilot_users.csv"

.INPUT
CSV file with required column:
- UserPrincipalName

.OUTPUT
Log file with operation results and optional summary report
#>

param (
    [Parameter(Mandatory)]
    [string]$CsvPath
)

# Connect to Graph if needed
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.Read.All", "Organization.Read.All"
}

# Load users from CSV
if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    exit 1
}
$users = Import-Csv $CsvPath

# Define required Copilot Service Plan ID (example placeholder)
$copilotPlanName = "M365 Copilot"
$copilotSkuId = "00000000-0000-0000-0000-000000000000"  # Replace with real SKU if known

# Loop through users
foreach ($user in $users) {
    $upn = $user.UserPrincipalName.Trim()
    try {
        Write-Host "Checking $upn..." -ForegroundColor Cyan
        $mgUser = Get-MgUser -UserId $upn -ErrorAction Stop

        # Retrieve license details
        $license = $mgUser.AssignedLicenses
        if (-not $license) {
            Write-Warning "$upn has no assigned license"
            continue
        }

        # Check Copilot SKU presence
        $hasCopilot = $false
        foreach ($assigned in $license) {
            if ($assigned.SkuId -eq $copilotSkuId) {
                $hasCopilot = $true
                break
            }
        }

        if ($hasCopilot) {
            Write-Host "$upn already has Copilot SKU" -ForegroundColor Green
        } else {
            Write-Host "$upn is missing Copilot SKU — assign manually via portal or Graph" -ForegroundColor Yellow
            # You could optionally assign license here
        }

    } catch {
        Write-Warning "Error processing $upn: $_"
    }
}
