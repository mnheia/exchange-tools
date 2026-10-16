<#
.SYNOPSIS
    Calculate mailbox sizes and total size (GiB).

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/exchange-tools
    License: GPL-3.0 (see LICENSE)
#>

param([string]$CsvPath)
$report = foreach ($mailbox in (Get-Mailbox -ResultSize Unlimited)) {
    try {
        $stats = Get-MailboxStatistics -Identity $mailbox.Identity -ErrorAction Stop
        $bytes = [long]$stats.TotalItemSize.Value.ToBytes()
        [pscustomobject]@{
            Mailbox = [string]$mailbox.PrimarySmtpAddress
            SizeGiB = [math]::Round($bytes / 1GB, 2)
            Bytes = $bytes
        }
    } catch { Write-Warning "Cannot read $($mailbox.Identity): $_" }
}
$report | Sort-Object SizeGiB -Descending | Format-Table -AutoSize
$sum = ($report | Measure-Object -Property Bytes -Sum).Sum
Write-Host ("Total: {0:N2} GiB" -f ($sum / 1GB))
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
