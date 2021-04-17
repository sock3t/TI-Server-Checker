# TI-Server-Checker
Checks the status of The Isle "Official Evrima Stress Test" Servers aka Update #3 Beta.

It is a Powershell Script that queries all currently known "Stress Test" servers and shows only those that currently have a slot free.

The script does not take any paramters, but it asks interactively to choose a region for which you want to check servers. So we only query servers which are relevant.

It also has a check that will recognize once you have made a successful connection with a The Isle server and will automatically cease further querying.

Note:
This tool depends on the PowerShell Module:
https://github.com/hjorslev/SteamPS
which in turn requires the "NuGet" PowerShell PackageProvider.

During startup the script will check the dependencies and install these if required. If you run the script as a non admin user then it will kick up the Windows UAC prompt to either confirm or even ask to enter admin credentials (depends on how your Windows system is set up). Once the dependecies are installed it won't ask for that again.