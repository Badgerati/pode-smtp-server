function Open-SmtpSqlConnection
{
    Open-SqliteConnection -FilePath (Join-Path (root) '/data/emails.db')
}

function Invoke-SmtpSqlQuery
{
    param (
        [string]
        $Query,

        [switch]
        $Return
    )

    try {
        Open-SmtpSqlConnection

        if (!$Return) {
            Invoke-SqlUpdate -Query $Query | Out-Null
        }
        else {
            return (Invoke-SqlQuery -Query $Query -AsDataTable)
        }
    }
    catch {
        Write-SmtpLogError -Exception $_
    }
    finally {
        Close-SqlConnection
    }
}

function New-SmtpSqlTable
{
    Invoke-SmtpSqlQuery -Query "
        CREATE TABLE IF NOT EXISTS Emails
        (
            EmailId INTEGER PRIMARY KEY AUTOINCREMENT,
            Subject TEXT,
            Sender TEXT,
            Recipients TEXT,
            Body TEXT,
            ContentType TEXT,
            Headers TEXT,
            IsUrgent INTEGER,
            TimeStamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    "
}

function Add-SmtpEmail
{
    param (
        [string]
        $Subject,

        [string]
        $From,

        [string[]] 
        $To,

        [string]
        $Body,

        [string]
        $ContentType,

        [hashtable]
        $Headers,

        [int]
        $IsUrgent
    )

    $Headers.Remove('Date') | Out-Null
    $Headers.Remove('To') | Out-Null
    $Headers.Remove('From') | Out-Null
    $Headers.Remove('Cc') | Out-Null
    $Headers.Remove('Bcc') | Out-Null
    $Headers.Remove('Subject') | Out-Null

    Invoke-SmtpSqlQuery -Query "
        INSERT INTO Emails (
            Subject,
            Sender,
            Recipients,
            Body,
            ContentType,
            Headers,
            IsUrgent
        )
        VALUES (
            `"$($Subject)`",
            `"$($From)`",
            `"$($To -join ', ')`",
            `"$($Body)`",
            `"$($ContentType)`",
            `"$(($Headers | ConvertTo-Json -Compress) -ireplace '"', "''")`",
            $($IsUrgent)
        )
    "
}

function Get-SmtpEmailCount
{
    $result = (Invoke-SmtpSqlQuery -Query "
        SELECT
            COUNT(1) AS Total
        FROM Emails
    " -Return)

    return [int]($result.Total)
}

function Get-SmtpEmails
{
    param (
        [int]
        $Limit = 10,

        [int]
        $Page = 1
    )

    if ($Limit -le 0) {
        $Limit = 10
    }

    if ($Page -le 0) {
        $Page = 1
    }

    $offset = (($Page - 1) * $Limit)

    $emails = (Invoke-SmtpSqlQuery -Query "
        SELECT
            EmailId,
            Subject,
            Sender,
            Recipients,
            Body,
            ContentType,
            Headers,
            IsUrgent,
            CAST(TimeStamp AS TEXT) AS TimeStamp
        FROM Emails
        ORDER BY EmailId DESC
        LIMIT $($Limit) OFFSET $($offset)
    " -Return)

    return (ConvertTo-SmtpEmails $emails)
}

function Get-SmtpEmailsForSender
{
    param (
        [string]
        $Email,

        [int]
        $Limit = 1
    )

    if ($Limit -le 0) {
        $Limit = 1
    }

    $emails = (Invoke-SmtpSqlQuery -Query "
        SELECT
            EmailId,
            Subject,
            Sender,
            Recipients,
            Body,
            ContentType,
            Headers,
            IsUrgent,
            CAST(TimeStamp AS TEXT) AS TimeStamp
        FROM Emails
        WHERE Sender LIKE `"%$($Email)%`"
        ORDER BY EmailId DESC
        LIMIT $($Limit)
    " -Return)

    return (ConvertTo-SmtpEmails $emails)
}

function Get-SmtpEmailsForRecipient
{
    param (
        [string]
        $Email,

        [int]
        $Limit = 1
    )

    if ($Limit -le 0) {
        $Limit = 1
    }

    $emails = (Invoke-SmtpSqlQuery -Query "
        SELECT
            EmailId,
            Subject,
            Sender,
            Recipients,
            Body,
            ContentType,
            Headers,
            IsUrgent,
            CAST(TimeStamp AS TEXT) AS TimeStamp
        FROM Emails
        WHERE Recipient LIKE `"%$($Email)%`"
        ORDER BY EmailId DESC
        LIMIT $($Limit)
    " -Return)

    return (ConvertTo-SmtpEmails $emails)
}

function Get-SmtpEmailForId
{
    param (
        [int]
        $EmailId
    )

    $email = (Invoke-SmtpSqlQuery -Query "
        SELECT
            EmailId,
            Subject,
            Sender,
            Recipients,
            Body,
            ContentType,
            Headers,
            IsUrgent,
            CAST(TimeStamp AS TEXT) AS TimeStamp
        FROM Emails
        WHERE EmailId = $($EmailId)
    " -Return)

    return (ConvertTo-SmtpEmails $email)
}

function Remove-SmtpEmailForId
{
    param (
        [int]
        $EmailId
    )

    Invoke-SmtpSqlQuery -Query "
        DELETE FROM Emails
        WHERE EmailId = $($EmailId)
    "
}

function Remove-SmtpOldEmails
{
    param (
        [int]
        $Ttl
    )

    Invoke-SmtpSqlQuery -Query "
        DELETE FROM Emails
        WHERE TimeStamp < DATETIME('now', '-$($Ttl) minute')
    "
}

function Remove-SmtpDataRowProperties
{
    param (
        [Parameter()]
        $DataRows
    )

    return ($DataRows | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors)
}

function ConvertTo-SmtpEmails
{
    param (
        [Parameter()]
        $DataRows
    )

    $Emails = @()

    (Remove-SmtpDataRowProperties $DataRows) | ForEach-Object {
        $Emails += @{
            'EmailId' = $_.EmailId;
            'Subject' = $_.Subject;
            'Sender' = $_.Sender;
            'Recipients' = $_.Recipients;
            'Body' = $_.Body;
            'ContentType' = $_.ContentType;
            'Headers' = (($_.Headers -ireplace "''", '"') | ConvertFrom-Json);
            'IsUrgent' = ([bool]$_.IsUrgent);
            'TimeStamp' = $_.TimeStamp;
        }
    }

    return $Emails
}

function Write-SmtpLogError
{
    param (
        [Parameter()]
        $Exception
    )

    $msg = "$($Exception.Exception.Message)`n$($Exception.ScriptStackTrace)"
    Write-SmtpLogMessage -Message $msg
}

function Write-SmtpLogMessage
{
    param (
        [Parameter()]
        [string]
        $Message
    )

    $date = "[$([datetime]::Now.ToString('HH:mm:ss'))]: "
    $Message = ("$($date)$($Message)`n" -ireplace "`n", "`n$($date)")

    $path = (Join-Path (root) "/logs/$([datetime]::Now.ToString('yyyy-MM-dd')).log")
    $parent = (Split-Path -Parent -Path $path)

    if (!(Test-Path $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }

    $Message | Out-File -FilePath $path -Encoding utf8 -Append -Force
}