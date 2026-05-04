# dwm_eotf_rs Installer Script
# This script downloads the latest dwm_eotf_rs.exe, installs it, and sets up a scheduled task to run at login

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Set variables
$installDir = "$env:ProgramFiles\dwm_eotf_rs"
$targetExeName = "dwm_eotf_rs.exe"
$batName = "run.bat"
$apiBaseUrl = "https://api.github.com/repos/SERGEYDJUM/dwm_eotf_rs/releases"

# Create temporary directory
$tempDir = "$env:TEMP\dwm_eotf_rs"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir
}

function Get-LevenshteinDistance {
    param (
        [string]$s,
        [string]$t
    )

    $n = $s.Length
    $m = $t.Length

    $d = New-Object 'int[,]' ($n + 1), ($m + 1)

    for ($i = 0; $i -le $n; $i++) { $d[$i,0] = $i }
    for ($j = 0; $j -le $m; $j++) { $d[0,$j] = $j }

    for ($i = 1; $i -le $n; $i++) {
        for ($j = 1; $j -le $m; $j++) {
            $cost = if ($s[$i - 1] -eq $t[$j - 1]) { 0 } else { 1 }

            $d[$i,$j] = [Math]::Min(
                [Math]::Min($d[$i-1,$j] + 1, $d[$i,$j-1] + 1),
                $d[$i-1,$j-1] + $cost
            )
        }
    }

    return $d[$n,$m]
}

function Get-BestExeFromReleases {
    param ([string]$baseUrl)

    try {
        $releases = Invoke-RestMethod -Uri "$baseUrl" -Method Get

        foreach ($release in $releases) {
            Write-Host "Checking release: $($release.tag_name)" -ForegroundColor Cyan
            $assets = Invoke-RestMethod -Uri $release.assets_url -Method Get

            $exeAssets = $assets | Where-Object { $_.name -like "*.exe" }

            if ($exeAssets) {
                # Score assets: higher score if name is closer to target
                $bestAsset = $null
                $highestScore = -1

                foreach ($asset in $exeAssets) {
                    # A simple scoring mechanism: string similarity/length difference
                    # For this use case, we check if it contains the target name or is very similar
                    $score = 0
                    $score = Get-LevenshteinDistance
                    if ($asset.name -eq $targetExeName) {
                        $score = 100
                    } elseif ($asset.name -like "*$targetExeName*") {
                        $score = 50
                    } else {
                        # Calculate similarity based on common substrings or simple distance
                        # Here we just use a fallback score for any other .exe
                        $score = 10
                    }

                    if ($score -gt $highestScore) {
                        $highestScore = $score
                        $bestAsset = $asset
                    }
                }

                if ($bestAsset) {
                    return $bestAsset.browser_download_url
                }
            }
            Write-Host "No .exe found in release $($release.tag_name). Trying previous release..." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Failed to fetch releases: $($_.Exception.Message)"
        return $null
    }
    return $null
}

try {
    # Find the best executable URL
    $downloadUrl = Get-BestExeFromReleases -baseUrl $apiBaseUrl

    if (-not $downloadUrl) {
        throw "Could not find a suitable .exe in any available releases."
    }

    Write-Host "Found download URL: $downloadUrl" -ForegroundColor Green
    $exePath = Join-Path $tempDir $targetExeName

    # Download the executable
    Write-Host "Downloading $targetExeName..." -ForegroundColor Green
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath

    # Create installation directory
    Write-Host "Creating installation directory: $installDir" -ForegroundColor Green
    if (!(Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force
    }

    # Copy executable to destination
    Write-Host "Copying $targetExeName to $installDir" -ForegroundColor Green
    Copy-Item -Path $exePath -Destination (Join-Path $installDir $targetExeName) -Force

    # Copy run.bat from current directory
    Write-Host "Copying run.bat to $installDir" -ForegroundColor Green
    Copy-Item -Path "$PSScriptRoot\run.bat" -Destination (Join-Path $installDir $batName) -Force

    # Create the scheduled task
    Write-Host "Setting up scheduled task to run at login with highest privileges" -ForegroundColor Green

    $taskName = "dwm_eotf_rs"
    $action = New-ScheduledTaskAction -Execute (Join-Path $installDir $batName) -WorkingDirectory $installDir
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1)
    $settings.ExecutionTimeLimit = 'PT0S'
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

    # Register the task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Runs dwm_eotf_rs at user login"

    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host "The dwm_eotf_rs utility is now installed and will run at each login with highest privileges." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during installation: $($_.Exception
    Write-Host "Installation failed." -ForegroundColor Red
}
finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
}
