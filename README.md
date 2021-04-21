# TI-Server-Checker
Checks the status of The Isle "Official Evrima Stress Test" Servers aka Update #3 Beta.

It is a Powershell Script that queries all currently known "Stress Test" servers and shows only those that currently have a slot free.

The script does not take any paramters, but it asks interactively to choose a region for which you want to check servers. So we only query servers which are relevant.

It also has a check that will recognize once you have made a successful connection with a The Isle server and will automatically cease further querying.

Note:
This tool depends on the PowerShell Module:
https://github.com/hjorslev/SteamPS
which in turn requires the "NuGet" PowerShell PackageProvider.

During startup the script will check the dependencies and install these if required. For that operation it will open a separate window and will show progress of the installation there. Once the depencies are installed it will not have to do that for subsequent runs.