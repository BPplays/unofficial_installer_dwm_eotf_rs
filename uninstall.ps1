# dwm_eotf_rs Uninstaller Script
# This script removes dwm_eotf_rs and its scheduled task

if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Set variables
$installDir = "$env:ProgramFiles\dwm_eotf_rs"
$taskName = "dwm_eotf_rs"

try {
    # Remove the scheduled task
    Write-Host "Removing scheduled task: $taskName" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false

    # Remove the installation directory
    Write-Host "Removing installation directory: $installDir" -ForegroundColor Yellow
    if (Test-Path $installDir) {
        Remove-Item -Recurse -Force $installDir
    }

    Write-Host "Uninstallation completed successfully!" -ForegroundColor Green
    Write-Host "dwm_eotf_rs has been removed from your system." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during uninstallation: $($_.Exception.Message)"
    Write-Host "Uninstallation may not have completed properly." -ForegroundColor Red
}
