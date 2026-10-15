# Export GUID-to-user mappings for migration and administration.
param([string]$OutputDirectory = '.')
New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
$users = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox |
    Select-Object DisplayName, SamAccountName, UserPrincipalName,
        @{N='ExchangeGuid';E={$_.ExchangeGuid.ToString().ToLowerInvariant()}}
$users | Export-Csv (Join-Path $OutputDirectory 'guid_map.csv') -NoTypeInformation -Encoding UTF8
$users | ForEach-Object { "$($_.SamAccountName): $($_.ExchangeGuid)" } |
    Set-Content (Join-Path $OutputDirectory 'guid_map.txt') -Encoding UTF8
