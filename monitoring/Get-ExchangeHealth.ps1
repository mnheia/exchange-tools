<#
.SYNOPSIS
    Read-only Exchange Server health summary. Run in Exchange Management Shell.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/exchange-tools
    License: GPL-3.0 (see LICENSE)
#>

param(
    [string[]]$Servers = @(),
    [int]$QueueWarning = 100,
    [int]$DiskWarningPercent = 15
)

if (-not (Get-Command Get-ExchangeServer -ErrorAction SilentlyContinue)) {
    throw 'Run this script in Exchange Management Shell.'
}
if (-not $Servers.Count) {
    $Servers = @(Get-ExchangeServer | Where-Object { $_.IsMailboxServer } | Select-Object -ExpandProperty Name)
}
foreach ($server in $Servers) {
    Write-Host "`n=== $server ===" -ForegroundColor Cyan
    Write-Host 'Unhealthy monitors:'
    try {
        $unhealthy = @(Get-ServerHealth -Identity $server -ErrorAction Stop |
            Where-Object { $_.AlertValue -notin @('Healthy','Disabled') })
        if ($unhealthy.Count) { $unhealthy | Select-Object HealthSetName,Name,AlertValue | Format-Table -AutoSize }
        else { Write-Host 'None' }
    } catch { Write-Warning "Server health: $_" }

    Write-Host 'Transport queues:'
    try {
        $queues = @(Get-Queue -Server $server -ErrorAction Stop)
        $queues | Select-Object Identity,Status,MessageCount | Format-Table -AutoSize
        if ($queues | Where-Object { $_.MessageCount -ge $QueueWarning }) { Write-Warning 'Large transport queue detected.' }
    } catch { Write-Warning "Queues: $_" }

    Write-Host 'Mailbox databases:'
    try {
        Get-MailboxDatabase -Server $server -Status -ErrorAction Stop |
            Select-Object Name,Mounted | Format-Table -AutoSize
    } catch { Write-Warning "Databases: $_" }

    Write-Host 'Available disk space:'
    try {
        Get-CimInstance Win32_LogicalDisk -ComputerName $server -Filter 'DriveType=3' -ErrorAction Stop |
            ForEach-Object {
                $freePct = if ($_.Size) { [math]::Round(100 * $_.FreeSpace / $_.Size, 1) } else { 0 }
                if ($freePct -le $DiskWarningPercent) { Write-Warning "$server $($_.DeviceID): only $freePct% free" }
                [pscustomobject]@{Drive=$_.DeviceID;FreeGB=[math]::Round($_.FreeSpace/1GB,1);FreePercent=$freePct}
            } | Format-Table -AutoSize
    } catch { Write-Warning "Disk check: $_" }
}
