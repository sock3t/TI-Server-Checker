function InstallNuGet
{
    if ((Get-PackageProvider -Name NuGet).version -lt 2.8.5.201 ) {
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$False -Force
        }
        catch [Exception]{
            $_.message 
            exit
        }
    }
    else {
        Write-Host "NuGet already installed"
    }
}
function InstallPreRequisites
{
    if (Get-Module -ListAvailable -Name SteamPS) {
        Write-Host "SteamPS already Installed"
    } 
    else {
        InstallNuGet
        try {
            Install-Module -Name SteamPS -AllowClobber -Confirm:$False -Force  
        }
        catch [Exception] {
            $_.message 
            exit
        }
    }
}
function WaitEnd
{
    Write-Host "Hit any key to continue or wait for 5 secs..."
    $counter = 0
    while(!$Host.UI.RawUI.KeyAvailable -and ($counter++ -lt 50))
    {
        Start-Sleep -Milliseconds 100
    }
}

# main
InstallPreRequisites
WaitEnd