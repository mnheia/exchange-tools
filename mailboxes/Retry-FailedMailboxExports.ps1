# Requeue failed export requests after examining their failure reason.
param(
    [Parameter(Mandatory)][string]$ExportPath,
    [string[]]$Identity,
    [switch]$AllFailed,
    [switch]$Execute
)
if (-not $Identity -and -not $AllFailed) { throw 'Specify -Identity or -AllFailed.' }
if (-not $ExportPath.StartsWith('\\')) { throw 'Use a UNC export path.' }

$failed = Get-MailboxExportRequest -ResultSize Unlimited | Where-Object { $_.Status -eq 'Failed' }
if (-not $AllFailed) { $failed = $failed | Where-Object { $Identity -contains [string]$_.Mailbox } }
foreach ($request in $failed) {
    $mailbox = Get-Mailbox -Identity $request.Mailbox -ErrorAction Stop
    $name = ([string]$mailbox.PrimarySmtpAddress -replace '[\\/:*?"<>|]', '_') + '.pst'
    $target = Join-Path $ExportPath $name
    Write-Host "Retry $($request.Identity) -> $target"
    if (-not $Execute) { continue }
    if (Test-Path -LiteralPath $target) { Write-Warning "Destination exists, skipping: $target"; continue }
    Remove-MailboxExportRequest -Identity $request.Identity -Confirm:$false -ErrorAction Stop
    New-MailboxExportRequest -Mailbox $mailbox.Identity -FilePath $target -ErrorAction Stop
}
