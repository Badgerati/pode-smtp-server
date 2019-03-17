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
    listen "*:$($config.web.port)" http

    # set the view engine
    engine pode

    # load routes
    load ./routes/api.ps1
    load ./routes/site.ps1
}