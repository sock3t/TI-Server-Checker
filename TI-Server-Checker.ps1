## Known Servers - this list is handcrafted
#AU1: 13.211.86.139
#AU2: 54.253.198.194
#BR1: 54.94.45.219
#BR2: 54.207.198.78
#BR3: 54.207.198.78
#NA1: 54.67.100.202
#NA2: 13.57.204.50
#NA3: 3.101.83.56
#NA4: 52.53.225.74
#NA5: 18.144.168.156
#NA6: 3.101.104.105
#NA7: 18.144.64.94
#NA8: 13.56.16.27
#EU1: 3.250.191.172
#EU2: 3.250.111.132
#EU3: 52.48.44.22
#EU4: 18.203.67.73
#EU5: 3.249.154.224
#EU6: 34.244.123.102
#EU7: 34.240.7.84
#EU8: 54.171.180.126
#EU9: 3.251.77.114
$Servers = "3.250.111.132", "52.48.44.22", "18.203.67.73", "3.249.154.224", "34.244.123.102", "34.240.7.84", "54.171.180.126", "3.251.77.114"

workflow GetAllServerInfo_w
{
    $Servers = "3.250.111.132", "52.48.44.22", "18.203.67.73", "3.249.154.224", "34.244.123.102", "34.240.7.84", "54.171.180.126", "3.251.77.114"
    ForEach -Parallel ($Server in $Servers)
    {
        Get-SteamServerInfo -IPAddress $Server -Port 27015 | Where-Object {$_.Players -lt $_.MaxPlayers} | Select-Object -Property "ServerName", "Players", "IPAddress" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima Stress Test - ", ""); $_ }
    }
}

Function GetAllServerInfo_f
{
    ForEach ($Server in $Servers)
    {
        Get-SteamServerInfo -IPAddress $Server -Port 27015 | Where-Object {$_.Players -lt $_.MaxPlayers} | Select-Object -Property "ServerName", "Players", "IPAddress" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima Stress Test - ", ""); $_ }
    }
}
function CheckPreRequisites
{
    if (Get-Module -ListAvailable -Name SteamPS) {
        Write-Host "SteamPS already Installed"
    } 
    else {
        $PrereqFile = "$pwd\Prerequisites.ps1"
        Start-Process -FilePath 'powershell' -Wait -ArgumentList ( '-NoProfile', $PrereqFile ) -verb RunAs        
    }
}

# Pre-Requisites:
CheckPreRequisites

# Main
DO
{
    $start = Get-Date
    $FreeServers = GetAllServerInfo_w
    #cls
    $FreeServers | Format-Table @{ e='*'; width = 25 }
    $end = Get-Date
    Write-Host -ForegroundColor Red ($end - $start).TotalSeconds
    
    $start = Get-Date
    $FreeServers = GetAllServerInfo_f
    #cls
    $FreeServers | Format-Table @{ e='*'; width = 25 }
    $end = Get-Date
    Write-Host -ForegroundColor Red ($end - $start).TotalSeconds

    #read-host "Press ENTER to continue..."
    Write-Host "Hit Ctrl+C to stop this script or just close the window."
    Start-Sleep -m 1000
} WHILE ($true)