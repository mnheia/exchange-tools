<#
.SYNOPSIS
    Delete old diagnostic logs only in folders explicitly supplied by the administrator.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/exchange-tools
    License: GPL-3.0 (see LICENSE)
#>

# Never target Exchange database transaction logs.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string[]]$Path,
    [int]$Days = 30,
    [switch]$Delete
)
$cutoff = (Get-Date).AddDays(-$Days)
foreach ($dir in $Path) {
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { throw "Missing folder: $dir" }
    $files = Get-ChildItem -LiteralPath $dir -Recurse -File |
        Where-Object { $_.Extension -in '.log','.blg','.etl' -and $_.LastWriteTime -lt $cutoff }
    foreach ($file in $files) {
        if ($Delete) {
            if ($PSCmdlet.ShouldProcess($file.FullName, 'Delete diagnostic log')) {
                Remove-Item -LiteralPath $file.FullName -ErrorAction Stop
            }
        } else {
            Write-Host "Would delete: $($file.FullName)"
        }
    }
}
