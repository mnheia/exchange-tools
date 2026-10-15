# Count Exchange SEND tracking events and recipients by sender.
param(
    [ValidateSet('Today','Yesterday','PreviousMonth')][string]$Period = 'Today',
    [string[]]$Domains = @(),
    [string[]]$ExcludeSenders = @(),
    [int]$MinimumMessages = 1,
    [int]$MinimumRecipients = 1,
    [string]$CsvPath
)
$now = Get-Date
switch ($Period) {
    'Today'         { $start = $now.Date; $end = $now }
    'Yesterday'     { $start = $now.Date.AddDays(-1); $end = $now.Date }
    'PreviousMonth' { $end = $now.Date.AddDays(1 - $now.Day); $start = $end.AddMonths(-1) }
}

# Message tracking may contain multiple SEND events for a message as it moves between servers.
$events = foreach ($server in (Get-TransportService)) {
    Get-MessageTrackingLog -Server $server.Name -Start $start -End $end -EventId SEND -ResultSize Unlimited
}
if ($Domains.Count) {
    $events = $events | Where-Object {
        $senderDomain = ([string]$_.Sender -split '@')[-1]
        $Domains -contains $senderDomain
    }
}
$events = $events | Where-Object { $ExcludeSenders -notcontains [string]$_.Sender }
$report = $events | Group-Object Sender | ForEach-Object {
    [pscustomobject]@{
        Sender = $_.Name
        Messages = $_.Count
        Recipients = ($_.Group | Measure-Object RecipientCount -Sum).Sum
    }
} | Where-Object { $_.Messages -ge $MinimumMessages -or $_.Recipients -ge $MinimumRecipients } |
    Sort-Object Messages -Descending
$report | Format-Table -AutoSize
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
