# get email for emailid
route get '/api/email/:id' {
    param($e)
    $id = [int]$e.Parameters['id']
    json @{
        'email' = (Get-SmtpEmailForId -EmailId $id);
    }
}

# delete email for emailid
route delete '/api/email/:id' {
    param($e)
    $id = [int]$e.Parameters['id']
    Remove-SmtpEmailForId -EmailId $id | Out-Null
}


# get emails
route get '/api/emails' {
    param($e)

    $limit = [int](coalesce $e.Query['limit'] 10)
    $page = [int](coalesce $e.Query['page'] 1)

    json @{
        'emails' = @(Get-SmtpEmails -Limit $limit -Page $page);
    }
}

# get emails for an address for sender
route get '/api/emails/sender' {
    param($e)

    $addr = [string]$e.Query['email']
    $limit = [int](coalesce $e.Query['limit'] 10)

    json @{
        'emails' = @(Get-SmtpEmailsForSender -Address $addr -Limit $limit)
    }
}

# get emails for an address for a recipient
route get '/api/emails/recipient' {
    param($e)

    $addr = [string]$e.Query['email']
    $limit = [int](coalesce $e.Query['limit'] 10)

    json @{
        'emails' = @(Get-SmtpEmailsForRecipient -Address $addr -Limit $limit)
    }
}