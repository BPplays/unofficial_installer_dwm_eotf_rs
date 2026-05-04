# dwm_eotf_rs Installer

This is an installer script that downloads the latest version of [dwm_eotf_rs](https://github.com/SERGEYDJUM/dwm_eotf_rs) and sets it up to run automatically at Windows login with highest privileges.

## What this tool does

The dwm_eotf_rs utility fixes Windows sRGB to scRGB "gamma" by patching DWM shaders. This tool requires admin rights and needs to run as a scheduled task at login to function properly.

## Features

- Downloads the latest version of dwm_eotf_rs.exe from GitHub
- Installs to Program Files directory
- Copies run.bat script to the installation directory
- Sets up a scheduled task to run at user login with highest privileges
- Works with the latest release (v0.9.3)

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or higher
- Admin privileges to run the installer

## Usage

1. Make sure you have admin privileges
2. Run the PowerShell script:
   ```powershell
   .\install.ps1
   ```

The script will:
1. Download the latest dwm_eotf_rs.exe from GitHub
2. Install to Program Files\dwm_eotf_rs
3. Create a scheduled task to run at login with highest privileges
4. The utility will continue running in the background to patch DWM shaders

## Files Created

- `Program Files\dwm_eotf_rs\dwm_eotf_rs.exe`
- `Program Files\dwm_eotf_rs\run.bat`
- Scheduled Task: "dwm_eotf_rs" (runs at login with highest privileges)

## Important Notes

- The tool requires admin rights to function properly
- The scheduled task runs with the same privileges as the currently logged-in user
- The utility patches windows DWM shaders to correct sRGB to scRGB gamma conversion