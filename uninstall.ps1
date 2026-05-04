# dwm_eotf_rs Uninstaller Script
# This script removes dwm_eotf_rs and its scheduled task

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