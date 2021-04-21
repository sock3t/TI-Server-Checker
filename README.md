# TI-Server-Checker
Checks the status of The Isle "Official Evrima Stress Test" Servers aka Update #3 Beta.

# What it does:
It is a Powershell Script that queries all currently known "Stress Test" servers and shows which one currently have a slot free.
It can also query a single server to achieve most accurate status of that server.

# How to use it:
The script does not take any parameters, but it asks interactively to choose a region for which you want to check servers. So we only query servers which are relevant.

It also has a check that will recognize once you have made a successful connection with a The Isle server and will automatically cease further querying.

# Install:
If you are unfamiliar with github and how to sync stuff from here you best bet is to just download a copy of this script:
* Click the green "Code" Button on the top right of this website and choose "Download ZIP"
* unpack the ZIP

# Run:
Right click the "TI-Server-Checker.ps1" file and choose "Run with PowerShell"

# Requirements:
* Powershell
  * any Windows 10 version and flavor should already be equipped
  * I have not tested Win 8 or lower - please let me know whether it works
* This tool depends on the PowerShell Module:
  https://github.com/hjorslev/SteamPS
  which in turn requires the "NuGet" PowerShell PackageProvider.
  * During startup the script will check the dependencies and install these if required. For that operation it will open a separate window and will show progress of the installation there. Once the depencies are installed it will not have to do that for subsequent runs.