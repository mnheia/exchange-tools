<#
.SYNOPSIS
    Queue Exchange on-premises mailbox exports to a PST share.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/exchange-tools
    License: GPL-3.0 (see LICENSE)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ExportPath,
    [ValidateSet('UserMailbox','LinkedMailbox')][string]$Type = 'UserMailbox',
    [string[]]$Identity,
    [switch]$All,
    [switch]$Execute
)
if ($Identity -and $All) { throw 'Specify -Identity or -All, not both.' }
if (-not $Identity -and -not $All) { throw 'Specify -Identity or -All.' }
if (-not $ExportPath.StartsWith('\\')) { throw 'Exchange exports require a UNC share.' }

$mailboxes = if ($All) {
    Get-Mailbox -RecipientTypeDetails $Type -ResultSize Unlimited
} else {
    foreach ($id in $Identity) { Get-Mailbox -Identity $id }
}
foreach ($mailbox in $mailboxes) {
    if ($mailbox.RecipientTypeDetails -ne $Type) { continue }
    $filename = ([string]$mailbox.PrimarySmtpAddress -replace '[\\/:*?"<>|]', '_') + '.pst'
    $target = Join-Path $ExportPath $filename
    if (Test-Path -LiteralPath $target) { Write-Warning "PST already exists: $target"; continue }
    if (Get-MailboxExportRequest -Mailbox $mailbox.Alias -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -in 'Queued','InProgress','CompletionInProgress' }) {
        Write-Warning "An export is already active for $($mailbox.Alias)"
        continue
    }
    if ($Execute) {
        New-MailboxExportRequest -Mailbox $mailbox.Identity -FilePath $target -ErrorAction Stop
    } else {
        Write-Host "Would export: $($mailbox.Identity) -> $target"
    }
}
