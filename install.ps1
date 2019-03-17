# install dependencies
Install-Module Pode -MinimumVersion 0.27.1 -Force

if ([string]::IsNullOrEmpty((Get-Command nssm -ErrorAction ignore))) {
    choco install nssm --version '2.24.101.20180116' -y
}

if ([string]::IsNullOrEmpty((Get-Command yarn -ErrorAction ignore))) {
    choco install yarn --version '1.15.2' -y
}

if ([string]::IsNullOrEmpty((Get-Module InvokeBuild -ErrorAction Ignore))) {
    Install-Module InvokeBuild -RequiredVersion '5.4.1'
}


# install and build dependencies
pode install
if (!(Test-Path ./pode_modules/bootstrap)) {
    pode install
}

pode build


# get the path to powershell
$exe = (Get-Command powershell.exe).Source


# name and path to server
$name = 'Pode SMTP Server'

if (!(nssm status $name)) {
    $file = (Join-Path $pwd 'smtp-server.ps1')
    $arg = "-ExecutionPolicy Bypass -NoProfile -Command `"$($file)`""

    # install and start
    nssm install $name $exe $arg
}

nssm start $name


# name and path to server
$name = 'Pode SMTP Web Server'

if (!(nssm status $name)) {
    $file = (Join-Path $pwd 'web-server.ps1')
    $arg = "-ExecutionPolicy Bypass -NoProfile -Command `"$($file)`""

    # install and start
    nssm install $name $exe $arg
}

nssm start $name