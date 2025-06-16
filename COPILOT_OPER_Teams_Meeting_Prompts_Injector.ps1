<#
.SYNOPSIS
Injects custom Copilot-ready prompts into Microsoft Teams meeting descriptions.

.DESCRIPTION
This script connects to Microsoft Graph, retrieves upcoming Teams meetings, and updates the meeting body
with structured prompts to guide Microsoft 365 Copilot during note-taking or task extraction.

.NOTES
Author: Ivan Garkusha
Version: 1.0
Filename: COPILOT_OPER_Teams_Meeting_Prompts_Injector.ps1
Date: 2025-06-16

.REQUIREMENTS
- Microsoft Graph PowerShell SDK
- Scopes: Calendars.ReadWrite, OnlineMeetings.ReadWrite

.EXAMPLE
.\COPILOT_OPER_Teams_Meeting_Prompts_Injector.ps1 -UserUpn 'john.doe@domain.com'
#>

param (
    [Parameter(Mandatory)]
    [string]$UserUpn,

    [string]$Prompt = "Copilot, please capture action items, highlight decisions, and tag project names."
)

# Connect to Graph if not connected
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Calendars.ReadWrite", "OnlineMeetings.ReadWrite"
}

Write-Host "Fetching upcoming meetings for $UserUpn..." -ForegroundColor Cyan
$now = Get-Date
$end = $now.AddDays(7).ToString("o")

# Get upcoming calendar events (next 7 days)
$meetings = Get-MgUserEvent -UserId $UserUpn -StartDateTime $now -EndDateTime $end -Property Subject,Body,Start,Id -Top 50

foreach ($meeting in $meetings) {
    $subject = $meeting.Subject
    $existingBody = $meeting.Body.Content
    $newBody = "$existingBody<br><br><b> Copilot Prompt:</b><br>$Prompt"

    try {
        Update-MgUserEvent -UserId $UserUpn -EventId $meeting.Id -Body @{ Content = $newBody; ContentType = "html" }
        Write-Host "Injected prompt into: $subject" -ForegroundColor Green
    } catch {
        Write-Host "Failed to update: $subject" -ForegroundColor Red
    }
}

Write-Host "`nAll eligible meetings processed."
