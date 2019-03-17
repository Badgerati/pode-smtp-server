# SMTP Server

This is a simple SMTP server for testing/dev purposes - built using [Pode](https://badgerati.github.io/Pode/) in PowerShell.

It has two servers, one for receiving email (`smtp-server.ps1`) and another for a front-end/rest-api site (`web-server.ps1`).

## Installing and Running

At the moment you just have to clone the repo, and it only supports Windows. Once cloned, you have two options to start running the servers:

1. Manually run the scripts:
    * First, install `Pode`, `Invoke-Build` and `Yarn`
    * At the root of the repo, run: `pode install` then `pode build`
    * In two seperate PowerShell sessions run each of the `smtp-server.ps1` and `web-server.ps1` scripts to start the servers running

2. Install the servers as Windows Services:
    * At the root of the repo, run the `install.ps1` script
    * This will install/build the dependencies and then setup the servers as Windows Services called `Pode SMTP Server` and `Pode SMTP Web Server`

Each server can then be accessed on the following endpoints:

* SMTP: Server - `localhost`, Port - `25`
* Web: `http://localhost:8025`

(These can be configured in the repo's `pode.json` file)

## Purging Emails

By default, the server is configured to automatically purge emails older than 2hrs (this can be configured in the repo's `pode.json` file).

## Web Site

The SMTP server's website can be accessed by default on `http://localhost:8025`, and allows you to see all emails being sent - including date/time, body, headers, recipients, etc.

## REST API

The default endpoint for the REST API is on `http://localhost:8025/api`:

| Endpoint | Description | QueryString |
| -------- | ----------- | ----------- |
| `GET /api/email/:id` | Given an EmailId, will return details about the email | none |
| `DELETE /api/email/:id` | Given an EmailId, will delete the email | none |
| `GET /api/emails` | Returns an array of paged emails | limit/page |
| `GET /api/emails/sender` | Returns an array of emails for an email address whom sent the email | email/limit |
| `GET /api/emails/recipient` | Returns an array of emails for an email address that received an email | email/limit |

### Examples

* Get email with ID 4:
    ```powershell
    Invoke-WebRequest 'http://localhost:8025/api/email/3' -Method Get
    ```

* Delete an email with ID 4:
    ```powershell
    Invoke-WebRequest 'http://localhost:8025/api/email/3' -Method Delete
    ```

* Get the first page of 10 emails, then get the 3rd page of 10 emails (emails are ordered by most recently sent):
    ```powershell
    Invoke-WebRequest 'http://localhost:8025/api/emails?limit=10&page=1' -Method Get
    Invoke-WebRequest 'http://localhost:8025/api/emails?limit=10&page=3' -Method Get
    ```

* Get the last 7 emails sent by an email address:
    ```powershell
    Invoke-WebRequest 'http://localhost:8025/api/emails/sender?email=bob@test.com&limit=7' -Method Get
    ```

* Get the last 7 emails received by an email address:
    ```powershell
    Invoke-WebRequest 'http://localhost:8025/api/emails/recipient?email=bob@test.com&limit=7' -Method Get
    ```