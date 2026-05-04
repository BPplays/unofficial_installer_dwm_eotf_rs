# dwm_eotf_rs Installer Script
# This script downloads the latest dwm_eotf_rs.exe, installs it, and sets up a scheduled task to run at login

# Set variables
$installDir = "$env:ProgramFiles\dwm_eotf_rs"
$exeName = "dwm_eotf_rs.exe"
$batName = "run.bat"
$githubReleaseUrl = "https://api.github.com/repos/SERGEYDJUM/dwm_eotf_rs/releases/latest"
$downloadUrl = "https://github.com/SERGEYDJUM/dwm_eotf_rs/releases/download/v0.9.3/dwm_eotf_rs.exe"

# Create temporary directory
$tempDir = "$env:TEMP\dwm_eotf_rs"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir
}

try {
    # Download the latest dwm_eotf_rs.exe
    Write-Host "Downloading dwm_eotf_rs.exe from GitHub..." -ForegroundColor Green
    $exePath = "$tempDir\dwm_eotf_rs.exe"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath

    # Create installation directory
    Write-Host "Creating installation directory: $installDir" -ForegroundColor Green
    if (!(Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force
    }

    # Copy dwm_eotf_rs.exe
    Write-Host "Copying dwm_eotf_rs.exe to $installDir" -ForegroundColor Green
    Copy-Item -Path $exePath -Destination "$installDir\$exeName"

    # Copy run.bat from current directory
    Write-Host "Copying run.bat to $installDir" -ForegroundColor Green
    Copy-Item -Path "$PSScriptRoot\run.bat" -Destination "$installDir\$batName"

    # Create the scheduled task
    Write-Host "Setting up scheduled task to run at login with highest privileges" -ForegroundColor Green

    $taskName = "dwm_eotf_rs"
    $action = New-ScheduledTaskAction -Execute "$installDir\$batName"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -RestartCount 0
    $settings.ExecutionTimeLimit = 'PT0S'
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken -RunLevel Highest

    # Register the task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Runs dwm_eotf_rs at user login"

    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host "The dwm_eotf_rs utility is now installed and will run at each login with highest privileges." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during installation: $($_.Exception.Message)"
    Write-Host "Installation failed." -ForegroundColor Red
}
finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
}
