<#
.SYNOPSIS
    Review Windows Security logon events (4624) from non-private IPv4 addresses.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/exchange-tools
    License: GPL-3.0 (see LICENSE)
#>

param([int]$HoursBack = 1, [string]$CsvPath)
$events = Get-WinEvent -FilterHashtable @{
    LogName='Security'; ID=4624; StartTime=(Get-Date).AddHours(-$HoursBack)
} -ErrorAction SilentlyContinue
$report = foreach ($event in $events) {
    [xml]$xml = $event.ToXml()
    $data = @{}
    foreach ($entry in $xml.Event.EventData.Data) { $data[$entry.Name] = $entry.'#text' }
    $ip = [string]$data['IpAddress']
    $parsed = $null
    if (-not [Net.IPAddress]::TryParse($ip, [ref]$parsed)) { continue }
    if ($parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) { continue }
    $b = $parsed.GetAddressBytes()
    if ($b[0] -in 0,10,127 -or $b[0] -ge 224 -or
        ($b[0] -eq 192 -and $b[1] -eq 168) -or
        ($b[0] -eq 172 -and $b[1] -ge 16 -and $b[1] -le 31) -or
        ($b[0] -eq 169 -and $b[1] -eq 254) -or
        ($b[0] -eq 100 -and $b[1] -ge 64 -and $b[1] -le 127)) { continue }
    if ($data['LogonType'] -ne '3' -or $data['TargetUserName'] -like '*$') { continue }
    [pscustomobject]@{Time=$event.TimeCreated;User=$data['TargetUserName'];IP=$ip;Type=$data['LogonType']}
}
$report | Sort-Object Time -Descending | Format-Table -AutoSize
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
