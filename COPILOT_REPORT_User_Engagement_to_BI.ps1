<#
.SYNOPSIS
Collects Microsoft 365 Copilot and collaboration engagement metrics per user for Power BI analysis.

.DESCRIPTION
This script gathers usage data across Outlook, Teams, and Copilot features (if available), exporting it to a structured CSV.
The output is suitable for ingestion by Power BI dashboards or further analysis in Excel/SharePoint.
Optionally publishes report to SharePoint document library.

.NOTES
Author: Ivan Garkusha
Date: 2025-06-16
Version: 1.0

.REQUIREMENTS
- Microsoft Graph PowerShell SDK
- Reports.Read.All or equivalent reporting permission
- Microsoft 365 usage reporting must be enabled

.PARAMETER OutputPath
Path to export the resulting CSV report

.PARAMETER SharePointUrl
Optional. If specified, uploads report to SharePoint site/library.
#>

param (
    [Parameter(Mandatory)]
    [string]$OutputPath,

    [string]$SharePointUrl
)

# Connect to Microsoft Graph
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Reports.Read.All", "Sites.ReadWrite.All"
}

Write-Host "Fetching user usage reports..." -ForegroundColor Cyan

# 1. Outlook activity
$outlook = Get-MgReportUserEmailActivityUserDetail -Date (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")

# 2. Teams activity
$teams = Get-MgReportUserTeamsActivityUserDetail -Date (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")

# 3. Copilot usage (if Microsoft enables via UsageReports in future)
try {
    $copilot = Get-MgReportCopilotUsageUserDetail -Date (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
} catch {
    $copilot = @()
}

# Join reports
$report = @()
foreach ($user in $outlook) {
    $userEmail = $user.UserPrincipalName
    $teamsEntry = $teams | Where-Object { $_.UserPrincipalName -eq $userEmail }
    $copilotEntry = $copilot | Where-Object { $_.UserPrincipalName -eq $userEmail }

    $report += [PSCustomObject]@{
        User            = $userEmail
        DisplayName     = $user.DisplayName
        LastSendDate    = $user.LastEmailSendDate
        TeamsMeetings   = $teamsEntry?.TotalMeetings
        TeamsMessages   = $teamsEntry?.ChatMessages
        CopilotUsage    = $copilotEntry?.CopilotSessions
    }
}

# Export to CSV
$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "✅ Exported report to: $OutputPath" -ForegroundColor Green

# Optional: upload to SharePoint
if ($SharePointUrl) {
    Write-Host "Uploading report to SharePoint..." -ForegroundColor Cyan
    Add-PnPStoredCredential -Name CopilotBI -Username "your-admin@tenant.com"
    Connect-PnPOnline -Url $SharePointUrl -Credentials "CopilotBI"

    Add-PnPFile -Path $OutputPath -Folder "Shared Documents/CopilotReports"
    Write-Host "✅ Uploaded to SharePoint" -ForegroundColor Green
}

