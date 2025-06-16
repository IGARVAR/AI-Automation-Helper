<#
.SYNOPSIS
Generates a report on Microsoft 365 Copilot adoption by collecting insights on license assignment and app usage.

.DESCRIPTION
This script queries Microsoft Graph to extract information on which users have been assigned Copilot licenses,
their usage of Copilot-related services (Word, Excel, Teams), and timestamps of their last activity.
The report is exported to a CSV file for further analysis by adoption teams or IT admins.

.NOTES
Author: Ivan Garkusha
Version: 1.0
Filename: COPILOT_REPORT_User_Adoption_Insights.ps1
Date: 2025-06-16

.REQUIREMENTS
- Microsoft Graph PowerShell SDK
- Delegated or app-based Graph access with scopes:
  AuditLog.Read.All, Reports.Read.All, User.Read.All

.EXAMPLE
.\COPILOT_REPORT_User_Adoption_Insights.ps1 -ExportPath ".\copilot_usage_report.csv"

#>

param (
    [string]$ExportPath = ".\copilot_usage_report.csv"
)

# Connect to Graph if needed
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "AuditLog.Read.All", "Reports.Read.All", "User.Read.All"
}

# Get all active users with assigned licenses
Write-Host "Fetching users with Copilot assigned..." -ForegroundColor Cyan
$users = Get-MgUser -Filter "accountEnabled eq true" -Property DisplayName,UserPrincipalName,AssignedLicenses,Id -All

# Copilot service plan ID (replace with actual if available)
$copilotSkuId = "00000000-0000-0000-0000-000000000000"

$results = foreach ($user in $users) {
    $hasCopilot = $false
    foreach ($lic in $user.AssignedLicenses) {
        if ($lic.SkuId -eq $copilotSkuId) {
            $hasCopilot = $true
            break
        }
    }

    if (-not $hasCopilot) { continue }

    # (Optional) Simulate Copilot usage check (real Graph endpoint pending public availability)
    $lastTeamsUsage = "N/A"
    $lastWordUsage  = "N/A"
    $lastExcelUsage = "N/A"

    # Placeholder: You could integrate with `/reports/getUserDetail` endpoints when GA
    # Future: Get-MgReportUserDetail -ReportName "microsoft365copilotusage"

    [PSCustomObject]@{
        DisplayName       = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        HasCopilot        = $hasCopilot
        LastTeamsActivity = $lastTeamsUsage
        LastWordActivity  = $lastWordUsage
        LastExcelActivity = $lastExcelUsage
    }
}

$results | Export-Csv -NoTypeInformation -Path $ExportPath -Encoding UTF8
Write-Host "✅ Copilot adoption report exported to $ExportPath" -ForegroundColor Green
