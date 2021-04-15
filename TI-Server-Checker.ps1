# Pre-Requisites:
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name SteamPS -Force
Set-ExecutionPolicy RemoteSigned -Force

## Known Servers - this list is handcrafted
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
    ForEach -Parallel ($Server in $Servers) {
        Get-SteamServerInfo -IPAddress $Server -Port 27015 | Select-Object -Property "Players"
    }
}

Function GetAllServerInfo_f
{
    ForEach ($Server in $Servers) {
        Get-SteamServerInfo -IPAddress $Server -Port 27015 | Where-Object {$_.Players -lt $_.MaxPlayers} | Select-Object -Property "ServerName", "Players", "IPAddress" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima Stress Test - ", ""); $_ }
    }
}

Function CreateTasks
{
    $global:task2 = { Get-SteamServerInfo -IPAddress '3.250.111.132' -Port 27015 | Select-Object -Property "Players" }
    $global:task3 = { Get-SteamServerInfo -IPAddress '52.48.44.22' -Port 27015 | Select-Object -Property "Players" }
    $global:task4 = { Get-SteamServerInfo -IPAddress '18.203.67.73' -Port 27015 | Select-Object -Property "Players" }
    $global:task5 = { Get-SteamServerInfo -IPAddress '3.249.154.224' -Port 27015 | Select-Object -Property "Players" }
    $global:task6 = { Get-SteamServerInfo -IPAddress '34.244.123.102' -Port 27015 | Select-Object -Property "Players" }
    $global:task7 = { Get-SteamServerInfo -IPAddress '34.240.7.84' -Port 27015 | Select-Object -Property "Players" }
    $global:task8 = { Get-SteamServerInfo -IPAddress '54.171.180.126' -Port 27015 | Select-Object -Property "Players" }
    $global:task9 = { Get-SteamServerInfo -IPAddress '3.251.77.114' -Port 27015 | Select-Object -Property "Players" }
}

Function StartJobs
{
    $global:job2 =  Start-Job -ScriptBlock $task2 
    $global:job3 =  Start-Job -ScriptBlock $task3
    $global:job4 =  Start-Job -ScriptBlock $task4
    $global:job5 =  Start-Job -ScriptBlock $task5
    $global:job6 =  Start-Job -ScriptBlock $task6
    $global:job7 =  Start-Job -ScriptBlock $task7
    $global:job8 =  Start-Job -ScriptBlock $task8
    $global:job9 =  Start-Job -ScriptBlock $task9
}

Function WaitForJobs
{
    # wait for the remaining tasks to complete (if not done yet)
    $null = Wait-Job -Job $job2, $job3, $job4, $job5, $job6, $job7, $job8, $job9
}

Function GetJobResults
{
    # now they are done, get the results
    $global:result2 = Receive-Job -Job $job2
    $global:result3 = Receive-Job -Job $job3
    $global:result4 = Receive-Job -Job $job4
    $global:result5 = Receive-Job -Job $job5
    $global:result6 = Receive-Job -Job $job6
    $global:result7 = Receive-Job -Job $job7
    $global:result8 = Receive-Job -Job $job8
    $global:result9 = Receive-Job -Job $job9
}

Function ClearJobs
{
    # discard the jobs
    Remove-Job -Job $job2, $job3, $job4, $job5, $job6, $job7, $job8, $job9
}

Function WriteJobResults
{
    # now they are done, get the results
    Write-Host $result2
    Write-Host $result3
    Write-Host $result4
    Write-Host $result5
    Write-Host $result6
    Write-Host $result7
    Write-Host $result8
    Write-Host $result9
}

DO
{
    #$start = Get-Date
    #GetAllServerInfo_w
    #$end = Get-Date
    #Write-Host -ForegroundColor Red ($end - $start).TotalSeconds
    
    $start = Get-Date
    $FreeServers = GetAllServerInfo_f
    cls
    $FreeServers | Format-Table @{ e='*'; width = 25 }
    $end = Get-Date
    Write-Host -ForegroundColor Red ($end - $start).TotalSeconds
    
    #$start = Get-Date
    #CreateTasks
    #StartJobs
    #WaitForJobs
    #GetJobResults
    #ClearJobs
    #WriteJobResults
    #$end = Get-Date
    #Write-Host -ForegroundColor Red ($end - $start).TotalSeconds

    #read-host “Press ENTER to continue...”
    Start-Sleep -m 1000
} WHILE ($true)