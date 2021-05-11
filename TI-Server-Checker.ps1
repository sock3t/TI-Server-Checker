<#
This tool relies on:
https://github.com/hjorslev/SteamPS

## Known Servers - this list is handcrafted
# Australia
#AU1: 13.211.86.139
#AU2: 54.253.198.194
# Brazil
#BR1: 54.94.45.219
#BR2: 54.207.198.78
#BR3: 52.67.88.139
## old #BR4: 15.228.90.72
#BR4: 54.232.65.187
#BR5: 18.228.154.111
#BR6: 18.231.145.14
# North America
#NA1: 54.67.100.202
#NA2: 13.57.204.50
#NA3: 3.101.83.56
#NA4: 52.53.225.74
#NA5: 18.144.168.156
#NA6: 3.101.104.105
#NA7: 18.144.64.94
#NA8: 13.56.16.27
# Europe
#EU1: 3.250.191.172 # is most of the time not used for the Update 3 beta
#EU2: 3.250.111.132
#EU3: 52.48.44.22
#EU4: 18.203.67.73
#EU5: 3.249.154.224 :51717
#EU6: 34.244.123.102
#EU7: 34.240.7.84
#EU8: 54.171.180.126
#EU9: 3.251.77.114
#>

$AUServers = 
    @{ip="13.211.86.139"; port=28015},
    @{ip="54.253.198.194"; port=28015}

$BRServers = 
    @{ip="54.94.45.219"; port=28015},
    @{ip="54.207.198.78"; port=28015},
    @{ip="52.67.88.139"; port=28015},
    @{ip="54.232.65.187"; port=28015},
    @{ip="18.228.154.111"; port=28015},
    @{ip="18.231.145.14"; port=28015}

$NAServers = 
    @{ip="54.67.100.202"; port=28015},
    @{ip="13.57.204.50"; port=28015},
    @{ip="3.101.83.56"; port=28015},
    @{ip="52.53.225.74"; port=28015},
    @{ip="18.144.168.156"; port=28015},
    @{ip="3.101.104.105"; port=28015},
    @{ip="18.144.64.94"; port=28015},
    @{ip="13.56.16.27"; port=28015}

$EUServers = 
    @{ip="3.250.191.172"; port=28015},
    @{ip="3.250.111.132"; port=28015},
    @{ip="52.48.44.22"; port=28015},
    @{ip="18.203.67.73"; port=28015},
    @{ip="3.249.154.224"; port=28015},
    @{ip="34.244.123.102"; port=28015},
    @{ip="34.240.7.84"; port=28015},
    @{ip="54.171.180.126"; port=28015},
    @{ip="3.251.77.114"; port=28015}

$Progress = ".", "o", "O", "0", "°", "´", "°", "0", "O", "o"

function Get-Serverlist
{
    Param(
        # Which group of servers to look for:
        # Official Evrima:
        # * AU: Australia
        # * BR: Brazil
        # * EU: Europe
        # * NA: North America
        # Community
        # * 'any other string': Only community servers that are currently full (the server "Die Insel der schrecklichen Echsen" is always in the list - it is the authors own server)
        $QUERY,
        # https://developer.valvesoftware.com/wiki/Master_Server_Query_Protocol#Filter - like "\full\1", "\empty\1", "\noplayers\1", etc.
        $PARAM
    )
    # https://developer.valvesoftware.com/wiki/Talk:Master_Server_Query_Protocol#new_API
    $uri = "https://api.steampowered.com/IGameServersService/GetServerList/v1/?key=4E9C85CBF2B369493F92DCE733EA3D31&filter=gamedir\theisle" + $PARAM + "&limit=999"
    # Get the server list
    $Servers = (Invoke-RestMethod -Uri $uri).response.Servers
    # initialize the array the we will return
    $ServerArr = @()
    switch -regex ( $QUERY )
    {
        '(AU|BR|EU|NA)'
        {
            $_querystring = "^Official Evrima .*" + $QUERY + ".*"
            Foreach ($Server in $Servers)
            {
                if ($Server.max_players -gt 0 -and $Server.Name -match "$_querystring")
                {
                    [string]$_ip = $Server.Addr.split(':')[0]
                    [string]$_port = $Server.Addr.split(':')[1]
                    [string]$_name = $Server.Name
                    $ServerArr += @{ip="$_ip"; port="$_port"; name="$_name"}
                }
            }
        }
        default
        {
            $_querystring = "(.*Echsen.*)"
            Foreach ($Server in $Servers)
            {
                if ($Server.max_players -gt 0 -and $Server.Name -notmatch "^Official Evrima .*" -and ($Server.players -ge $Server.max_players -or $Server.Name -match "$_querystring"))
                {
                    [string]$_ip = $Server.Addr.split(':')[0]
                    [string]$_port = $Server.Addr.split(':')[1]
                    [string]$_name = $Server.Name
                    $ServerArr += @{ip="$_ip"; port="$_port"; name="$_name"}
                }
            }
        }
    }
    $ServerArr = $ServerArr | Sort-Object { $_.name }
    return ,$ServerArr
}

function Send-UdpDatagram
# https://gist.github.com/PeteGoo/21a5ab7636786670e47c
{
    Param ([string] $EndPoint,
    [int] $Port,
    [string] $Message)

    $IP = [System.Net.Dns]::GetHostAddresses($EndPoint)
    $Address = [System.Net.IPAddress]::Parse($IP)
    $EndPoints = New-Object System.Net.IPEndPoint($Address, $Port)
    $Socket = New-Object System.Net.Sockets.UDPClient

    $EncodedText = [Text.Encoding]::utf8.GetBytes($Message)

    $SendMessage = $Socket.Send($EncodedText, $EncodedText.Length, $EndPoints)

    # https://stackoverflow.com/a/47440927
    $ReceiveEndPoint = new-object net.ipendpoint([net.ipaddress]::any, 0)
    $receiveMessage = $Socket.receive([ref]$ReceiveEndPoint)

    Write-Host "received message:"
    $arr = $receiveMessage[6..($receiveMessage.Length-1)]
    #$arr = $receiveMessage[6..11]
    $counter = 0
    $iparr = @()
    Do
    {
        [string]$_ip = ""
        For ($i=1; $i -le 4; $i++) {
            #Write-Host -NoNewline $arr[$counter]
            # If we dont convert to string then the _ip var will be casted to int and this will mess up the array / hashtable
            $_ip += $arr[$counter].ToString()
            if ($i%4 -ne 0) 
            {
                #Write-Host -NoNewline "."
                $_ip += "."
            }
            $counter++
        }
        $a = $arr[$counter]
        $counter++
        $b = $arr[$counter]
        # https://stackoverflow.com/a/24458649
        $short = -Join (("{0:X}" -f $a),("{0:X}" -f $b))
        #Write-Host -NoNewline ":"
        #Write-Host ([convert]::ToInt64($short,16))
        $_port = ([convert]::ToInt64($short,16))
        # https://www.alkanesolutions.co.uk/2016/11/22/powershell-array-hashtables-instead-multidimensional-array/
        $iparr += (@{ip="$_ip"; port="$_port"})
        $counter++
    } While ($counter -lt $arr.Length)
    #$arr
    #$list = ([text.encoding]::utf7.getstring($receiveMessage))
    #$list

    $Socket.Close()
    #https://stackoverflow.com/questions/12620375/how-to-return-several-items-from-a-powershell-function/12621314
    # 
    return ,$iparr
} 

workflow GetAllServerInfo_w
{
    $Servers = "13.211.86.139", "54.253.198.194", "54.94.45.219", "54.207.198.78", "52.67.88.139", "54.67.100.202", "13.57.204.50", "3.101.83.56", "52.53.225.74", "18.144.168.156", "3.101.104.105", "18.144.64.94", "13.56.16.27", "3.250.191.172", "3.250.111.132", "52.48.44.22", "18.203.67.73", "3.249.154.224", "34.244.123.102", "34.240.7.84", "54.171.180.126", "3.251.77.114"
    ForEach -Parallel ($Server in $Servers)
    {
        Get-SteamServerInfo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -IPAddress $Server.ip -Port $Server.port | Where-Object {$_.Players -lt $_.MaxPlayers} | Select-Object -Property "ServerName", "Players", "IPAddress" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima ", ""); $_ }
    }
}

Function GetAllServerInfo_f
{
    ForEach ($Server in $Servers)
    {
        try {
            # show only servers which have slots free
            #Get-SteamServerInfo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Timeout 400 -IPAddress $Server.ip -Port $Server.port | Where-Object {$_.Players -lt $_.MaxPlayers} | Add-Member -MemberType AliasProperty -Name Ver -Value GameName -PassThru | Select-Object -Property "ServerName", "Players", "MaxPlayers", "Ver" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima ", ""); $_.Ver = $_.Ver.Replace("Evrima ", ""); $_ }
            # show all server currently reachable
            # DEBUG - with name correction, not used anymore with new server list gathering method
            #Get-SteamServerInfo -IPAddress $Server.ip -Port $Server.port | Add-Member -MemberType AliasProperty -Name Ver -Value GameName -PassThru | Select-Object -Property "ServerName", "Players", "MaxPlayers", "Ver" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima ", ""); $_.Ver = $_.Ver.Replace("Evrima ", ""); $_ }
            Get-SteamServerInfo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Timeout 400 -IPAddress $Server.ip -Port $Server.port | Add-Member -MemberType AliasProperty -Name Ver -Value GameName -PassThru | Select-Object -Property "ServerName", "Players", "MaxPlayers", "Ver"
        }
        catch [Exception] {
            #$_.message
        }
        
    }
}
Function GetServerInfo
{
    Param(
        $IP,
        $PORT
    )
    try {
        # DEBUG
        #Get-SteamServerInfo -IPAddress $IP -Port 28015 | Add-Member -MemberType AliasProperty -Name Ver -Value GameName -PassThru | Select-Object -Property "ServerName", "Players", "MaxPlayers", "Ver" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima ", ""); $_.Ver = $_.Ver.Replace("Evrima ", ""); $_ }
        #Get-SteamServerInfo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Timeout 400 -IPAddress $IP -Port $PORT | Add-Member -MemberType AliasProperty -Name Ver -Value GameName -PassThru | Select-Object -Property "ServerName", "Players", "MaxPlayers", "Ver" | % { $_.ServerName = $_.ServerName.Replace("Official Evrima ", ""); $_.Ver = $_.Ver.Replace("Evrima ", ""); $_ }
        Get-SteamServerInfo -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Timeout 400 -IPAddress $IP -Port $PORT | Add-Member -MemberType AliasProperty -Name Ver -Value GameName -PassThru | Select-Object -Property "ServerName", "Players", "MaxPlayers", "Ver"
    }
    catch [Exception] {
        #$_.message
    }
}

function Show-Region-Menu
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
    Write-Host "'c' Community Servers"
    Write-Host "'q' to quit"
}
function Show-Server-Menu
{
    param (
        [string]$Title = 'Servers'
    )
    Clear-Host
    $ServerID = 0
    Write-Host "Please choose a server:"
    Write-Host "================ $Title ================"
    ForEach ($Server in $Servers)
    {
        $ServerID++
        if ($RegionCode -ne "C")
        {
            try {
                $_fake = [System.Net.Dns]::GetHostEntry($Server.ip.Trim()).HostName
            }
            catch {
                $_fake = "No Hostname"
            }
        }
        if ($RegionCode -ne "C" -and $_fake -notmatch ".*compute.amazonaws.com")
        {
            Write-Host "'${ServerID}' "$Server.name"- this one might be fake! ($($Server.ip))"
        }
        else 
        {
            Write-Host "'${ServerID}' "$Server.name
        }
        
    
    }
    Write-Host "'a' check all (Only for checking the availability of servers and for timing when to press the 'Refresh' button!)"
    Write-Host "'q' return to region menu"
    
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

function Get-NetworkStatistics
{
    <#
    Based on this work:
    https://lazywinadmin.com/2011/02/how-to-find-running-processes-and-their.html
    #>
    $properties = 'Protocol','LocalAddress','LocalPort'
    $properties += 'RemoteAddress','RemotePort','State','ProcessName','PID'

    netstat -ano | Select-String -Pattern '\s+(UDP)' | ForEach-Object {

        $item = $_.line.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)

        if($item[1] -notmatch '^\[::')
        {
            if (($la = $item[1] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6')
            {
                $localAddress = $la.IPAddressToString
                $localPort = $item[1].split('\]:')[-1]
            }
            else
            {
                $localAddress = $item[1].split(':')[0]
                $localPort = $item[1].split(':')[-1]
            }

            if (($ra = $item[2] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6')
            {
                $remoteAddress = $ra.IPAddressToString
                $remotePort = $item[2].split('\]:')[-1]
            }
            else
            {
                $remoteAddress = $item[2].split(':')[0]
                $remotePort = $item[2].split(':')[-1]
            }

            New-Object PSObject -Property @{
                PID = $item[-1]
                ProcessName = (Get-Process -Id $item[-1] -ErrorAction SilentlyContinue).Name
                Protocol = $item[0]
                LocalAddress = $localAddress
                LocalPort = $localPort
                RemoteAddress =$remoteAddress
                RemotePort = $remotePort
                State = if($item[0] -eq 'tcp') {$item[3]} else {$null}
            } | Select-Object -Property $properties
        }
    }
}

function CheckConnection
{
    $TrafficHits = 0
    Do
    {
        $port = Get-NetworkStatistics | Where-Object {$_.ProcessName -eq 'steam' -and $_.LocalPort -ge 28000 -and $_.LocalAddress -ne "0.0.0.0" -and $_.LocalAddress -ne "127.0.0.1"} | Select-Object -ExpandProperty LocalPort
        if (![string]::IsNullOrWhiteSpace($port))
        {
            $TrafficHits++
            if ($TrafficHits -eq 1)
            {
                Write-Host
                Write-Host "#######################################"
                Write-Host "## Connection attempt in progress... ##"
                Write-Host "#######################################"
            }
            if ($TrafficHits -ge 30)
            {
                return $true
            }
            Start-Sleep -s 1
        }
    } While (![string]::IsNullOrWhiteSpace($port))
    if ($TrafficHits -gt 0)
    {
        Write-Host
        Write-Host "#######################################################"
        Write-Host "## I know it's hard... that's why I wrote this tool. ##"
        Write-Host "##                                                   ##"
        Write-Host "##     But it can only do the clicking for you.      ##"
        Write-Host "##      For the last meter you need some luck,       ##"
        Write-Host "##      a bit more patience and fast reflexes.       ##"
        Write-Host "##                                                   ##"
        Write-Host "## -- Keep going!                                    ##"
        Write-Host "#######################################################"
        Start-Sleep -s 10
        break
    }
    return $false
}

function CheckPreRequisites
{
    if (Get-Module -ListAvailable -Name SteamPS) {
        #Write-Host "SteamPS already Installed"
        #WaitEnd
    } 
    else {
        Set-ExecutionPolicy RemoteSigned -Force
        $PrereqFile = "$pwd\Prerequisites.ps1"
        Start-Process -FilePath 'powershell' -Wait -ArgumentList ( '-NoProfile', $PrereqFile )
    }
}

# Pre-Requisites:
CheckPreRequisites

# Main
do
{
    Show-Region-Menu

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
            $RegionCode = "AU"
            #$Servers = $AUServers
            $Servers = Get-Serverlist "AU" "\empty\1\name_match\Official Evrima *"
        }
        'B' {
            $region = "Brazil"
            $RegionCode = "BR"
            #$Servers = $BRServers
            $Servers = Get-Serverlist "BR" "\empty\1\name_match\Official Evrima *"
        }
        'E' {
            $region = "Europe"
            $RegionCode = "EU"
            #$Servers = $EUServers
            $Servers = Get-Serverlist "EU" "\empty\1\name_match\Official Evrima *"
        }
        'N' {
            $region = "North America"
            $RegionCode = "NA"
            #$Servers = $NAServers
            $Servers = Get-Serverlist "NA" "\empty\1\name_match\Official Evrima *"
        }
        'C' {
            $region = "Community Servers"
            $RegionCode = "C"
            #$Servers = $CommunityServers

            #Send-UdpDatagram -EndPoint "hl2master.steampowered.com" -Port 27011 -Message "1.0.0.0.0:0.\appid\412680."
            # https://developer.valvesoftware.com/wiki/Master_Server_Query_Protocol
            # https://steamdb.info/app/412680/
            # => "1.0.0.0.0:0.\appid\412680." => Text -> HEX 34 31 32 36 38 30 (The Isle Dedicated Server)
            # => "1.0.0.0.0:0.\appid\376210 => Text -> HEX 33 37 36 32 31 30 (The Isle)
            $message = 
            # character "1" + region code x03 = Europe
            [char]0x31+[char]0x03+
            # 0.0.0.0:0
            [char]0x30+[char]0x2e+[char]0x30+[char]0x2e+[char]0x30+[char]0x2e+[char]0x30+[char]0x3a+[char]0x30+
            [char]0x00+
            # \appid
            [char]0x61+[char]0x70+[char]0x70+[char]0x69+[char]0x64+
            # \gamedir
            #[char]0x5c+[char]0x67+[char]0x61+[char]0x6d+[char]0x65+[char]0x64+[char]0x69+[char]0x72+
            # \theisle
            #[char]0x5c+[char]0x74+[char]0x68+[char]0x65+[char]0x69+[char]0x73+[char]0x6c+[char]0x65+
            # \412680
            #[char]0x5c+[char]0x34+[char]0x31+[char]0x32+[char]0x36+[char]0x38+[char]0x30+
            # \376210
            [char]0x5c+[char]0x33+[char]0x37+[char]0x36+[char]0x32+[char]0x31+[char]0x30+
            [char]0x00
            #Send-UdpDatagram -EndPoint "208.64.200.39" -Port 27011 -Message $message
            #Send-UdpDatagram -EndPoint "208.64.200.52" -Port 27011 -Message $message
            #Send-UdpDatagram -EndPoint "208.64.200.65" -Port 27011 -Message $message
            #$Servers = Send-UdpDatagram -EndPoint "208.64.200.39" -Port 27011 -Message $message
            $Servers = Get-Serverlist "" ""
        }
    }
    if ($char -ne 'q')
    {
        do
        {
            Show-Server-Menu
            # we need to clear the input buffer so the last key input does not interfere with the next one
            Start-Sleep -Milliseconds 100
            $host.ui.RawUI.FlushInputBuffer();

            $key = [Console]::ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
            $char = $key.KeyChar

            # clear input buffer again so it does not break the next loop early
            Start-Sleep -Milliseconds 100
            $host.ui.RawUI.FlushInputBuffer();

            if ($char -ne 'q')
            {
                # this is a hack to convert the char from the keypress into an integer:
                [Int32]$idx = 0
                if ([System.Int32]::TryParse($char, [ref]$idx))
                {
                    # if 3 is pressed then the array index 2 is what we want to work on because array start counting from 0 instead of 1
                    $idx--
                    $Server = $Servers[$idx]
                }
                do
                {
                    <#
                    # https://devblogs.microsoft.com/powershell/powershell-foreach-object-parallel-feature/
                    # ^^ this does only speed up if a lot of servers are queried. But usuallly we want to check only the Official servers for our own region
                    # I keep this for future reference in case the usage of this script ever gets expanded.
                    
                    $start = Get-Date
                    $FreeServers = GetAllServerInfo_w
                    Clear-Host
                    $FreeServers | Format-Table @{ e='*'; width = 25 }
                    $end = Get-Date
                    Write-Host -ForegroundColor Red ($end - $start).TotalSeconds
                    #>

                    #$start = Get-Date
                    if ($char -eq "a")
                    {
                        $ServerInfo = GetAllServerInfo_f
                    }
                    else {
                        # DEBUG
                        #Write-Host $Server
                        $ServerInfo = GetServerInfo -IP $Server.ip -PORT $Server.port
                        # DEBUG
                        #Write-Host $ServerInfo
                        #Start-Sleep -m 100 
                    }
                    
                    Clear-Host
                    $ts = Get-date
                    Write-Host $ts
                    Write-Host
                    Write-Host -NoNewLine $region": "

                    $modcount++
                    $step = $modcount%$Progress.Length
                    Write-Host -NoNewLine $Progress[$step]

                    # escape character so we can write color escape codes
                    $e = [char]27
                    $ServerInfo | Format-Table -AutoSize @{
                        Label = "ServerName"
                        Expression =
                        {
                            if ($_.Players -lt $_.MaxPlayers) {
                                $fgcolor = "32"
                                $bgcolor = "40"
                            }
                            elseif ($_.Players -gt $_.MaxPlayers) {
                                $fgcolor = "31"
                                $bgcolor = "40"
                            }
                            elseif ($_.Players -eq $_.MaxPlayers) {
                                $fgcolor = "0"
                                $bgcolor = "0"
                            }
                            "$e[${fgcolor};${bgcolor}m$($_.ServerName)"
                        }
                    }, Players, MaxPlayers, Ver
                    # cancel all color codes after printing the qtable
                    "${e}[0m"
                    Write-Host "($($Server.ip))"
                    
                    #$end = Get-Date
                    #Write-Host -ForegroundColor Red ($end - $start).TotalSeconds

                    Write-Host "Hit any key to get back to the Region selection."

                    if ($char -ne "a")
                    {
                        if ($ServerInfo.Players -lt $ServerInfo.MaxPlayers)
                        {
                            if (CheckConnection)
                            {
                                Write-Host
                                Write-Host
                                Write-Host "###############################################################"
                                Write-Host "## Connection to The Isle server detected. Stopping queries. ##"
                                Write-Host "###############################################################"
                                Start-Sleep -s 10
                                break
                            }
                            # add a little extra delay (slow down queries) as long as we see a free slot
                            Start-Sleep -Milliseconds 200
                        }
                        elseif ($ServerInfo.Players -gt $ServerInfo.MaxPlayers) {
                            # slow down queries as long as the server is just spammed with connection attempts anyway
                            Start-Sleep -Milliseconds 300
                        }
                    }
                } until ($Host.UI.RawUI.KeyAvailable)
            }
        } until ($char -eq 'q')
        $char = ""
    }
} until ($char -eq 'q')