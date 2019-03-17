# migrate assets from pode_modules/ to public/
task assets {
    # create base dirs
    New-item -Path './public/js' -ItemType Directory -Force | Out-Null
    New-item -Path './public/css' -ItemType Directory -Force | Out-Null

    # move bootstrap files
    Copy-Item -Path './pode_modules/bootstrap/dist/css/*.min.*' -Destination './public/css' -Force | Out-Null
    Copy-Item -Path './pode_modules/bootstrap/dist/js/*.min.*' -Destination './public/js' -Force | Out-Null

    # move jquery files
    Copy-Item -Path './pode_modules/jquery/dist/*.min.*' -Destination './public/js' -Force | Out-Null

    # move popper files
    Copy-Item -Path './pode_modules/popper.js/dist/*.min.*' -Destination './public/js' -Force | Out-Null
}