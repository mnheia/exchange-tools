# Review PST export progress and failures.
param([string]$CsvPath)
$report = Get-MailboxExportRequest -ResultSize Unlimited |
    Get-MailboxExportRequestStatistics |
    Select-Object Mailbox, Status, PercentComplete, TotalMailboxSize, FilePath
$report | Sort-Object PercentComplete | Format-Table -AutoSize
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
