# dwm_eotf_rs Installer

install:
```pwsh
$script = "install"; Set-ExecutionPolicy Bypass -Scope Process; New-Item -ItemType Directory -Path "$env:TEMP\dwm_eotf_rs_inst" -Force; Invoke-WebRequest -Uri https://raw.githubusercontent.com/BPplays/unofficial_installer_dwm_eotf_rs/refs/heads/main/$script.ps1 -OutFile "$env:TEMP\dwm_eotf_rs_inst\$script.ps1"; & "$env:TEMP\dwm_eotf_rs_inst\$script.ps1"
```

uninstall:
```pwsh
$script = "uninstall"; Set-ExecutionPolicy Bypass -Scope Process; New-Item -ItemType Directory -Path "$env:TEMP\dwm_eotf_rs_inst" -Force; Invoke-WebRequest -Uri https://raw.githubusercontent.com/BPplays/unofficial_installer_dwm_eotf_rs/refs/heads/main/$script.ps1 -OutFile "$env:TEMP\dwm_eotf_rs_inst\$script.ps1"; & "$env:TEMP\dwm_eotf_rs_inst\$script.ps1"
```
