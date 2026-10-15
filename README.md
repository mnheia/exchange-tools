Copyright (c) 2026, Mnheia <mnheia@gmail.com>

# exchange-tools

PowerShell scripts for on-premises Microsoft Exchange administration, reporting and maintenance. Run in **Exchange Management Shell** (Windows PowerShell 5.1) with the appropriate RBAC permissions.

## Mailboxes

- `mailboxes/Export-Mailboxes.ps1` — PST export for user or linked mailboxes; preview unless `-Execute` is given.
- `mailboxes/Get-MailboxExportStatus.ps1` — list current PST export requests and progress.
- `mailboxes/Retry-FailedMailboxExports.ps1` — retry failed requests; preview unless `-Execute` is given.
- `mailboxes/Get-MailboxSizes.ps1` — report total and per-mailbox disk usage.
- `mailboxes/Export-MailboxGuids.ps1` — export mailbox GUID mappings.
- `mailboxes/Export-MailboxInventory.ps1` — CSV list of mailboxes, optionally including AD and mailbox last-logon data.

```powershell
.\mailboxes\Export-Mailboxes.ps1 -ExportPath '\\fileserver\pst' -Identity 'user@example.com'
.\mailboxes\Export-Mailboxes.ps1 -ExportPath '\\fileserver\pst' -Identity 'user@example.com' -Execute
.\mailboxes\Export-MailboxInventory.ps1 -CsvPath '.\mailboxes.csv' -IncludeLogons
```

`New-MailboxExportRequest` requires the **Mailbox Import Export** role and a UNC share writable by the Exchange Trusted Subsystem. Exporting a mailbox creates sensitive PST data. Use an access-controlled share.

## Reports

- `reports/Get-MailTraffic.ps1` — per-sender SEND-event and recipient-count report for today, yesterday or the previous month.
- `monitoring/Get-ExternalWindowsLogons.ps1` — Security event 4624 network logon events from public IPv4 sources.
- `maintenance/Remove-OldExchangeDiagnosticLogs.ps1` — delete old `.log`, `.blg` and `.etl` diagnostic logs in specified folders when `-Delete` is given.

```powershell
.\reports\Get-MailTraffic.ps1 -Period PreviousMonth -Domains example.com -CsvPath '.\mail-traffic.csv'
.\maintenance\Remove-OldExchangeDiagnosticLogs.ps1 -Path 'C:\Program Files\Microsoft\Exchange Server\V15\Logging' -Days 30
```


## Exchange health

- `monitoring/Get-ExchangeHealth.ps1` — Exchange health monitors, transport queues, mailbox database state, and available disk space.

```powershell
.\monitoring\Get-ExchangeHealth.ps1
.\monitoring\Get-ExchangeHealth.ps1 -Servers EX01 -QueueWarning 100 -DiskWarningPercent 15
```

Run from Exchange Management Shell. These checks are read-only; the disk check requires remote CIM access.

## Bugs

Please report issues at https://github.com/mnheia/exchange-tools/issues

## License

GPL-3.0; see `LICENSE`.
