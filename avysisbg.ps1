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
        $newProcesses | ForEach-Object {
            $hash = (Get-FileHash -Path $_ -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
            if ($falsePositives.Contains($hash)) {
                return
            }
            $api = @{"query_status" = "avysis_error" }
            try {
                $oldpref = $ProgressPreference
                $ProgressPreference = "SilentlyContinue"
                $api = Invoke-RestMethod "https://mb-api.abuse.ch/api/v1/" -Method Post -Body "query=get_info&hash=$hash"
                $ProgressPreference = $oldpref
            }
            catch {}
            if ($api.query_status -eq "ok") {
                $basename = (Get-Item $_).BaseName
                get-process $basename | stop-process
                [System.Windows.MessageBox]::Show("We blocked a file containing malware.", "Blocked file", 0, 64)
            } 
        }
        $pString = $cpString
        $processes = $currentProcesses
    }
    Start-Sleep -Milliseconds 250
}
