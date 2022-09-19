Add-Type -AssemblyName PresentationCore, PresentationFramework

$falsePositives = @("D41D8CD98F00B204E9800998ECF8427E")
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$processes = Get-Process | Select-Object -ExpandProperty Path
$pString = $processes | Out-String
while ($true) {
    $currentProcesses = Get-Process | Select-Object -ExpandProperty Path
    $cpString = $currentProcesses | Out-String
    if ($pString -ne $cpString) {
        $newProcesses = $currentProcesses | Where-Object { $_ -notin $processes }
        $newProcesses | % {
            $hash = (Get-FileHash -Path $_ -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
            if ($falsePositives.Contains($hash)) {
                return
            }
            $api = @{"query_status" = "avysis_error" }
            try {
                $oldpref = $ProgressPreference
                $ProgressPreference = "SilentlyContinue"
                $api = Invoke-RestMethod "https://urlhaus-api.abuse.ch/v1/payload/" -Method Post -Body "md5_hash=$hash"
                $ProgressPreference = $oldpref
            }
            catch {}
            if ($api.query_status -eq "ok") {
                $signature = $api.signature
                if ($signature -eq $null) { $signature = "Malware" }
                $basename = (Get-Item $_).Name
                $actualBasename = (Get-Item $_).Basename
                $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?", $_, 4, 48)
                if ($msgbox -eq 6) {
                    start-process powershell.exe -ArgumentList "get-process $actualBasename | stop-process; del '$_' -Force" -Verb RunAs
                }
            } 
        }
        $pString = $cpString
        $processes = $currentProcesses
    }
    Start-Sleep -Milliseconds 250
}
