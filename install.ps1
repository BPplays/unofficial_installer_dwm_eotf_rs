# dwm_eotf_rs Installer Script
# This script downloads the latest dwm_eotf_rs.exe, installs it, and sets up a scheduled task to run at login

# Check for Administrator privileges
if ($args[0] -ne "-test") {
    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $script = $MyInvocation.MyCommand.Definition
        $bytes  = [System.Text.Encoding]::Unicode.GetBytes($script)
        $encoded = [Convert]::ToBase64String($bytes)

        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
        exit
    }
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

function Get-JaroWinklerDistance {
    param (
        [string]$s1,
        [string]$s2
    )

    if ($s1 -eq $s2) { return 1.0 }

    $len1 = $s1.Length
    $len2 = $s2.Length
    if ($len1 -eq 0 -or $len2 -eq 0) { return 0.0 }

    $max_dist = [Math]::Floor([Math]::Max($len1, $len2) / 2) - 1
    if ($max_dist -lt 0) { $max_dist = 0 }

    $m = 0
    $t = 0
    $s1_chars = $s1.ToCharArray()
    $s2_chars = $s2.ToCharArray()
    $p1 = New-Object bool[] $len1
    $p2 = New-Object bool[] $len2

    for ($i = 0; $i -lt $len1; $i++) {
        $start = [Math]::Max(0, $i - $max_dist)
        $end = [Math]::Min($i + $max_dist + 1, $len2)
        for ($j = $start; $j -lt $end; $j++) {
            if (-not $p2[$j] -and $s1_chars[$i] -eq $s2_chars[$j]) {
                $p1[$i] = $true
                $p2[$j] = $true
                $m++
                break
            }
        }
    }

    if ($m -eq 0) { return 0.0 }

    $k = 0
    for ($i = 0; $i -lt $len1; $i++) {
        if ($p1[$i]) {
            while (-not $p2[$k]) { $k++ }
            if ($s1_chars[$i] -ne $s2_chars[$k]) { $t++ }
            $k++
        }
    }

    $jaro = ($m / $len1 + $m / $len2 + ($m - ($t / 2.0)) / $m) / 3.0

    # Winkler adjustment
    $l = 0
    $p = 0.1
    while ($l -lt [Math]::Min(4, [Math]::Min($len1, $len2)) -and $s1_chars[$l] -eq $s2_chars[$l]) {
        $l++
    }
    return $jaro + ($l * $p * (1.0 - $jaro))
}

function Test-JaroWinkler {
    Write-Host "Running Jaro-Winkler Distance Tests..." -ForegroundColor Cyan
    $tests = @(
        @{ s1 = "dwm_eotf_rs.exe"; s2 = "dwm_eotf_rs.exe"; expected = 1.0 }
        @{ s1 = "dwm_eotf_rs-neo.exe"; s2 = "dwm_eotf_rs.exe"; expected = 0.9 }
        @{ s1 = "apple"; s2 = "apply"; expected = 0.9 } # Approximate
        @{ s1 = "abc"; s2 = "def"; expected = 0.0 }
        @{ s1 = "test"; s2 = ""; expected = 0.0 }
    )

    $passed = 0
    foreach ($test in $tests) {
        $result = Get-JaroWinklerDistance -s1 $test.s1 -s2 $test.s2
        if ($result -ge $test.expected -or $test.expected -eq 0) {
            Write-Host "PASS: '$($test.s1)' vs '$($test.s2)' -> Result: $result" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "FAIL: '$($test.s1)' vs '$($test.s2)' -> Result: $result (Expected approx $($test.expected))" -ForegroundColor Red
        }
    }
    Write-Host "`nTests Passed: $passed / $($tests.Count)" -ForegroundColor Cyan
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
                $bestAsset = $null
                $highestScore = -1

                foreach ($asset in $exeAssets) {
                    $score = Get-JaroWinklerDistance -s1 $asset.name -s2 $targetExeName
                    Write-Host "  - Score for '$($asset.name)': $score" -ForegroundColor Gray

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

# MAIN EXECUTION
if ($args[0] -eq "-test") {
    Test-JaroWinkler
    exit
}

try {
    # Find the best executable URL
    $downloadUrl = Get-BestExeFromReleases -baseUrl $apiBaseUrl

    if (-not $downloadUrl) {
        throw "Could not find a suitable .exe in any available releases."
    }

    Write-Host "Found download URL: $downloadUrl" -ForegroundColor Green
    $exePath = Join-Path $tempDir $targetExeName

    Write-Host "Downloading $targetExeName..." -ForegroundColor Green
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath

    Write-Host "Creating installation directory: $installDir" -ForegroundColor Green
    if (!(Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force
    }

    Write-Host "Copying $targetExeName to $installDir" -ForegroundColor Green
    Copy-Item -Path $exePath -Destination (Join-Path $installDir $targetExeName) -Force

    Write-Host "Copying run.bat to $installDir" -ForegroundColor Green
    Copy-Item -Path "$PSScriptRoot\run.bat" -Destination (Join-Path $installDir $batName) -Force

    Write-Host "Setting up scheduled task to run at login with highest privileges" -ForegroundColor Green

    $taskName = "dwm_eotf_rs"
    $taskPath = "\Users\$env:USERNAME\"
    $action = New-ScheduledTaskAction -Execute (Join-Path $installDir $batName) -WorkingDirectory $installDir
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1)
    $settings.ExecutionTimeLimit = 'PT0S'
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

    Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Runs dwm_eotf_rs at user login"

    Write-Host "Installation completed successfully!" -ForegroundColor Green
    # Ask user
    $response = Read-Host "Run the task now? (Y/n)"

    if (-not ($response -match '^(n|no)$')) {
        try {
            Start-ScheduledTask -TaskName $taskName -TaskPath $taskPath
            Write-Host "Task started." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to start task: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "Task will run at next logon." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "An error occurred during installation: $($_.Exception.Message)"
    Write-Host "Installation failed." -ForegroundColor Red
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
}
