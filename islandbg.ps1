Add-Type -AssemblyName PresentationCore, PresentationFramework
$processes = Get-Process | Select-Object -ExpandProperty Path
$pString = $processes | Out-String
while ($true) {
    $currentProcesses = Get-Process | Select-Object -ExpandProperty Path
    $cpString = $currentProcesses | Out-String
    if ($pString -ne $cpString) {
        $newProcesses = $currentProcesses | Where-Object {$_ -notin $processes}
        $newProcesses | % {
                $hash = (Get-FileHash -Path $_ -Algorithm MD5).Hash
                $api = Invoke-RestMethod "https://urlhaus-api.abuse.ch/v1/payload/" -Method Post -Body "md5_hash=$hash"
                if ($api.query_status -eq "ok") {
                    $signature = $api.signature
                    if ($signature -eq $null) {$signature = "Malware"}
                    $basename = (Get-Item $_).Name
                    $actualBasename = (Get-Item $_).Basename
                    $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?",$_,4,48)
                    if ($msgbox -eq 6) {
                        get-process $actualBasename | stop-process
                        start-process powershell.exe -ArgumentList "del '$_' -Force" -Verb RunAs
                    }
                } 
        }
        $pString = $cpString
        $processes = $currentProcesses
    }
}