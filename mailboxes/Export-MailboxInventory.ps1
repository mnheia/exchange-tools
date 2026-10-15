# Export an Exchange mailbox inventory, optionally including AD and mailbox logon metadata.
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [switch]$IncludeLogons
)
if ($IncludeLogons) { Import-Module ActiveDirectory -ErrorAction Stop }
$report = foreach ($mb in (Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox)) {
    $item = [ordered]@{
        DisplayName = $mb.DisplayName
        SamAccountName = $mb.SamAccountName
        UserPrincipalName = $mb.UserPrincipalName
        PrimarySmtpAddress = [string]$mb.PrimarySmtpAddress
    }
    if ($IncludeLogons) {
        $stats = Get-MailboxStatistics -Identity $mb.Identity -ErrorAction SilentlyContinue
        $ad = Get-ADUser -Identity $mb.SamAccountName -Properties LastLogonDate,Enabled,PasswordLastSet -ErrorAction SilentlyContinue
        $item['MailboxLastLogon'] = $stats.LastLogonTime
        $item['ADLastLogonDate'] = $ad.LastLogonDate
        $item['ADEnabled'] = $ad.Enabled
        $item['PasswordLastSet'] = $ad.PasswordLastSet
    }
    [pscustomobject]$item
}
$report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $(@($report).Count) mailboxes to $CsvPath"
