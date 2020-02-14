If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\CPU-nanominer181\nanominer.exe"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v1.8.1/nanominer-windows-1.8.1.zip"
$Commands = [PSCustomObject]@{ 
    #"Ethash" = "" #GPU Only
    #"Ubqhash" = "" #GPU Only
    #"Cuckaroo30" = "" #GPU Only
    #"RandomX" = "" #CPU only
    "RandomHash2" = "" #CPU only
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    Switch ($_) { 
        "randomhash" { $Fee = 0.05 } # substract devfee
        default { $Fee = 0.01 } # substract devfee
    }

    $ConfigFileName = "$((@("Config") + @($Algo) + @($Algorithm_Norm) + @($Variables.CPUMinerAPITCPPort) + @($Pools.$Algo.User) | Select-Object) -join '-').ini"
    $Arguments = [PSCustomObject]@{ 
        ConfigFile = [PSCustomObject]@{ 
        FileName = $ConfigFileName
        Content  = "
; NemoMiner autogenerated config file (c) nemosminer.com
checkForUpdates=false
mport=0
noLog=true
rigName=$($Config.WorkerName)
watchdog=false
webPort=$($Variables.CPUMinerAPITCPPort)

[$($_)]
pool1=$($Pools.$Algo.Host):$($Pools.$Algo.Port)
wallet=$($Pools.$Algo.User)"
        }
        Commands = "$ConfigFileName"
    }

    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = $Arguments
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) } # substract devfee
        API       = "nanominer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
