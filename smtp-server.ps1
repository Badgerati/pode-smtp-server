Import-Module Pode -MinimumVersion 0.27.1 -Force -ErrorAction Stop

Server -Threads 3 {
    # get pode config
    $config = Get-PodeConfiguration

    # dependencies
    import -n SimplySql
    import -n ./modules/tools.psm1

    # create the database
    New-SmtpSqlTable

    # bind to endpoint
    listen "*:$($config.smtp.port)" smtp

    # handle any incoming emails
    handler smtp {
        param($e)
        Add-SmtpEmail -Subject $e.Subject -From $e.From -To $e.To -Body $e.Body `
            -ContentType $e.ContentType -Headers $e.Headers -IsUrgent $e.IsUrgent
    }

    # create schedule to auto-purge email
    if (([bool]$config.smtp.purge.enable) -and ([int]$config.smtp.purge.ttl) -gt 0) {
        schedule 'purge_email' '0/5 * * * *' {
            $config = Get-PodeConfiguration
            Remove-SmtpOldEmails -Ttl $config.smtp.purge.ttl
        }
    }
}