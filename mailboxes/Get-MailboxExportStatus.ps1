<#
.SYNOPSIS
    Review PST export progress and failures.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/exchange-tools
    License: GPL-3.0 (see LICENSE)
#>

param([string]$CsvPath)
$report = Get-MailboxExportRequest -ResultSize Unlimited |
    Get-MailboxExportRequestStatistics |
    Select-Object Mailbox, Status, PercentComplete, TotalMailboxSize, FilePath
$report | Sort-Object PercentComplete | Format-Table -AutoSize
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
