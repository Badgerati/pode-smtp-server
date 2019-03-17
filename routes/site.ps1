# main page
route get '/' {
    param($e)

    $limit = [int](coalesce $e.Query['limit'] 10)
    $page = [int](coalesce $e.Query['page'] 1)

    $emails = (Get-SmtpEmails -Limit $limit -Page $page)
    $count = (Get-SmtpEmailCount)

    $total = ([math]::Ceiling($count / $limit))
    if ($total -eq 0) {
        $total = 1
    }

    $config = (Get-PodeConfiguration)

    view 'index' @{
        'emails' = $emails;
        'title' = $config.web.title;
        'meta' = @{
            'count' = $count;
            'limit' = $limit;
            'pages' = @{
                'total' = $total;
                'current' = $page;
            };
        };
    }
}