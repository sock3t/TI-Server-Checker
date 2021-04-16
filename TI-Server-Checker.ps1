<#
This tool is based on:
https://github.com/hjorslev/SteamPS

## Known Servers - this list is handcrafted
#AU1: 13.211.86.139
#AU2: 54.253.198.194
#BR1: 54.94.45.219
#BR2: 54.207.198.78
#BR3: 52.67.88.139
#NA1: 54.67.100.202
#NA2: 13.57.204.50
#NA3: 3.101.83.56
#NA4: 52.53.225.74
#NA5: 18.144.168.156
#NA6: 3.101.104.105
#NA7: 18.144.64.94
#NA8: 13.56.16.27
#EU1: 3.250.191.172 # is most of the time not used for the Update 3 beta
#EU2: 3.250.111.132
#EU3: 52.48.44.22
#EU4: 18.203.67.73
#EU5: 3.249.154.224
#EU6: 34.244.123.102
#EU7: 34.240.7.84
#EU8: 54.171.180.126
#EU9: 3.251.77.114
#>

$AUServers = "13.211.86.139", "54.253.198.194"
$BRServers = "54.94.45.219", "54.207.198.78", "52.67.88.139"
$NAServers = "54.67.100.202", "13.57.204.50", "3.101.83.56", "52.53.225.74", "18.144.168.156", "3.101.104.105", "18.144.64.94", "13.56.16.27"
$EUServers = "3.250.111.132", "52.48.44.22", "18.203.67.73", "3.249.154.224", "34.244.123.102", "34.240.7.84", "54.171.180.126", "3.251.77.114"


workflow GetAllServerInfo_w
{
    $Servers = "13.211.86.139", "54.253.198.194", "54.94.45.219", "54.207.198.78", "52.67.88.139", "54.67.100.202", "13.57.204.50", "3.101.83.56", "52.53.225.74", "18.144.168.156", "3.101.104.105", "18.144.64.94", "13.56.16.27", "3.250.191.172", "3.250.111.132", "52.48.44.22", "18.203.67.73", "3.249.154.224", "34.244.123.102", "34.240.7.84", "54.171.180.126", "3.251.77.114"
    ForEach -Parallel ($Server in $Servers)
    {
        Get-SteamServerInfo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -IPAddress $Server -Port 27015 | Where-Object {$_.Players -lt $_.MaxPlayers} | Select-Object -Property "ServerName", "Players", "IPAddress" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima ", ""); $_ }
    }
}

Function GetAllServerInfo_f
{
    ForEach ($Server in $Servers)
    {
        try {
            Get-SteamServerInfo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Timeout 400 -IPAddress $Server -Port 27015 | Where-Object {$_.Players -lt $_.MaxPlayers} | Select-Object -Property "ServerName", "Players", "IPAddress" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima ", ""); $_ }
        }
        catch [Exception] {
            #$_.message
        }
        
    }
}

function Show-Menu
{
    param (
        [string]$Title = 'Regions'
    )
    Clear-Host
    Write-Host "Please choose a region:"
    Write-Host "================ $Title ================"
    Write-Host "'a' Australia"
    Write-Host "'b' Brazil"
    Write-Host "'e' Europe"
    Write-Host "'n' North America"
    Write-Host "'q' to quit"
}
function WaitEnd
{
    Write-Host "Hit any key to continue or wait for 5 secs..."
    Start-Sleep -Milliseconds 100
    $host.ui.RawUI.FlushInputBuffer();
    $counter = 0
    while(!$Host.UI.RawUI.KeyAvailable -and ($counter++ -lt 50))
    {
        Start-Sleep -Milliseconds 100
    }
}

function CheckPreRequisites
{
    if (Get-Module -ListAvailable -Name SteamPS) {
        Write-Host "SteamPS already Installed"
        WaitEnd
    } 
    else {
        $PrereqFile = "$pwd\Prerequisites.ps1"
        Start-Process -FilePath 'powershell' -Wait -ArgumentList ( '-NoProfile', $PrereqFile ) -verb RunAs        
    }
}

# Pre-Requisites:
CheckPreRequisites

# Main
do
{
    Show-Menu

    # we need to clear the input buffer so the last key input does not interfere with the next one
    Start-Sleep -Milliseconds 100
    $host.ui.RawUI.FlushInputBuffer();

    $key = [Console]::ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
    $char = $key.KeyChar

    # clear input buffer again so it does not break the next loop early
    Start-Sleep -Milliseconds 100
    $host.ui.RawUI.FlushInputBuffer();

    switch ($char)
    {
        'A' {
            $region = "Australia"
            $Servers = $AUServers
        }
        'B' {
            $region = "Brazil"
            $Servers = $BRServers
        }
        'E' {
            $region = "Europe"
            $Servers = $EUServers
        }
        'N' {
            $region = "North America"
            $Servers = $NAServers
        }
    }
    if ($char -ne 'q')
    {
        do
        {
            <#
            # https://devblogs.microsoft.com/powershell/powershell-foreach-object-parallel-feature/
            # ^^ this does only speed up if a lot of servers are queried. But usuallly we want to check only the Official servers for our own region
            
            $start = Get-Date
            $FreeServers = GetAllServerInfo_w
            Clear-Host
            $FreeServers | Format-Table @{ e='*'; width = 25 }
            $end = Get-Date
            Write-Host -ForegroundColor Red ($end - $start).TotalSeconds
            #>

            #$start = Get-Date
            $FreeServers = GetAllServerInfo_f

            Clear-Host
            $ts = Get-date
            Write-Host $ts
            Write-Host
            Write-Host $region

            $FreeServers | Format-Table @{ e='*'; width = 25 }
            #$end = Get-Date
            #Write-Host -ForegroundColor Red ($end - $start).TotalSeconds

            Write-Host "Hit any key to get back to the Region selection."
            Start-Sleep -m 1000
        }
        until ($Host.UI.RawUI.KeyAvailable)
    }
}
until ($char -eq 'q')