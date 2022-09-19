Add-Type -AssemblyName System.Windows.Forms, PresentationCore, PresentationFramework

$protected = ! ! (Get-Process avysisbg -ErrorAction SilentlyContinue)
$falsePositives = @("D41D8CD98F00B204E9800998ECF8427E")
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Truncate-Text([string]$Text, [int]$Length) {
    if ($Text.Length -gt $Length) {
        return ($Text.Substring(0, $Length) + "...")
    }
    else {
        return $Text
    }
}

Function Get-Folder($initialDirectory = "") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if ($foldername.ShowDialog() -eq "OK") {
        $folder += $foldername.SelectedPath
        return $folder
    }
    else {
        return $null
    }
}
$form = New-Object Windows.Forms.Form
$form.Text = "Avysis"
$form.Width = "390"
$form.Height = "105"
$form.FormBorderStyle = 'Fixed3D'
$form.MaximizeBox = $false
$form.TopMost = $True
$form.ShowIcon = $false
$prtext = New-Object Windows.Forms.Label
if ($protected) {
    $prtext.Text = "You're protected"
    $prtext.ForeColor = "green"
}
else {
    $prtext.Text = "You're not protected"
    $prtext.ForeColor = "red"
}
$prtext.Location = New-Object Drawing.Point(8, 7)
$prtext.Font = New-Object Drawing.Font("", 14)
$prtext.AutoSize = $true
$scan = New-Object Windows.Forms.Button
$scan.text = "Scan"
$scan.Location = New-Object Drawing.Point(10, 40)
$scan.Add_Click({
        $Result = [System.Windows.MessageBox]::Show("Really perform this operation?", "Confirm", 4, 32)
        if ($Result -eq 7) {
            return
        }
        $folder = @((New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path, (New-Object -ComObject Shell.Application).NameSpace('shell:start menu').Self.Path, $env:TEMP)
        $items = Get-ChildItem $folder -Recurse -ErrorAction SilentlyContinue | Where { ! $_.PSIsContainer }
        $completed = 0
        $has_threat = $false
        $items | % {
            $completed += 1
            $percent = [Math]::Round(($completed / ($items | Measure-Object).count * 100))
            $name = $_.Name
            $truncatedName = Truncate-Text -Text $name -Length 12
            if (! $truncatedName.EndsWith("...")) {
                $truncatedName += "."
            }
            Write-Progress -Activity "Scan" -Status "Avysis is scanning your computer. This may take a while. Scanning file $truncatedName $percent% complete." -PercentComplete $percent
            $hash = (Get-FileHash -Path $_.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
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
                $has_threat = $true
                $signature = $api.signature
                if ($signature -eq $null) { $signature = "Malware" }
                $basename = (Get-Item $_.FullName).Name
                $actualBasename = (Get-Item $_.FullName).Basename
                $fullname = $_.FullName
                $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?", $fullname, 4, 48)
                if ($msgbox -eq 6) {
                    start-process powershell.exe -ArgumentList "get-process $actualBasename | stop-process; del '$fullname' -Force" -Verb RunAs
                }
            }
        }
        Write-Progress -Activity "Scan" -Status "Ready" -Completed
        if (!($has_threat)) {
            [System.Windows.MessageBox]::Show("No threats!", "No threats!", 0, 64)
        }
    })
$scanfldr = New-Object Windows.Forms.Button
$scanfldr.text = "Scan folder"
$scanfldr.Location = New-Object Drawing.Point(90, 40)
$scanfldr.Add_Click({
        $folder = Get-Folder
        if ($folder -eq $null) { return }
        $Result = [System.Windows.MessageBox]::Show("Really perform this operation?", "Confirm", 4, 32)
        if ($Result -eq 7) {
            return
        }
        $items = Get-ChildItem $folder -Recurse | Where { ! $_.PSIsContainer }
        $completed = 0
        $has_threat = $false
        $items | % {
            $completed += 1
            $percent = [Math]::Round(($completed / ($items | Measure-Object).count * 100))
            $name = $_.Name
            $truncatedName = Truncate-Text -Text $name -Length 12
            if (! $truncatedName.EndsWith("...")) {
                $truncatedName += "."
            }
            Write-Progress -Activity "Scan a folder" -Status "Avysis is scanning a folder. This may take a while. Scanning file $truncatedName $percent% complete." -PercentComplete $percent
            $hash = (Get-FileHash -Path $_.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
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
                $has_threat = $true
                $signature = $api.signature
                if ($signature -eq $null) { $signature = "Malware" }
                $basename = (Get-Item $_.FullName).Name
                $actualBasename = (Get-Item $_.FullName).Basename
                $fullname = $_.FullName
                $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?", $fullname, 4, 48)
                if ($msgbox -eq 6) {
                    start-process powershell.exe -ArgumentList "del '$fullname' -Force" -Verb RunAs
                }
            }
        }
        Write-Progress -Activity "Scan a folder" -Status "Ready" -Completed
        if (!($has_threat)) {
            [System.Windows.MessageBox]::Show("No threats!", "No threats!", 0, 64)
        }
    })
$scanfile = New-Object Windows.Forms.Button
$scanfile.text = "Scan file"
$scanfile.Location = New-Object Drawing.Point(170, 40)
$scanfile.Add_Click({
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Filter           = 'All files|*'
        }
        $null = $FileBrowser.ShowDialog()
        if (!($FileBrowser.FileName)) { return }
        $hash = (Get-FileHash -Path $FileBrowser.FileName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
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
            $basename = $FileBrowser.SafeFileName
            $actualBasename = (Get-Item $FileBrowser.FileName).Basename
            $filename = $FileBrowser.FileName
            $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?", $FileBrowser.FileName, 4, 48)
            if ($msgbox -eq 6) {
                start-process powershell.exe -ArgumentList "get-process $actualBasename | stop-process; del '$filename' -Force" -Verb RunAs
            }
        }
        else {
            [System.Windows.MessageBox]::Show("No threats!", "No threats!", 0, 64)
        }
    })
$tempdisable = New-Object Windows.Forms.Button
$tempdisable.text = "Disable temporarily"
$tempdisable.Location = New-Object Drawing.Point(250, 40)
$tempdisable.Width = 120
$tempdisable.Add_Click({
        Get-Process avysisbg | Stop-Process
        $prtext.Text = "You're not protected"
        $prtext.ForeColor = "red"
        $form.controls.remove($tempdisable)
        $form.controls.add($reenable)
        $form.Width = "345"
    })
$reenable = New-Object Windows.Forms.Button
$reenable.text = "Re-enable"
$reenable.Location = New-Object Drawing.Point(250, 40)
$reenable.Add_Click({
        $bgprocess = (Get-ItemProperty Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run).Avysis
        Start-Process -FilePath $bgprocess
        $prtext.Text = "You're protected"
        $prtext.ForeColor = "green"
        $form.controls.add($tempdisable)
        $form.controls.remove($reenable)
        $form.Width = "390"
    })
$form.controls.add($prtext)
$form.controls.add($scan)
$form.controls.add($scanfldr)
$form.controls.add($scanfile)
$form.controls.add($tempdisable)
if (! $protected) {
    $form.controls.remove($tempdisable)
    $form.controls.add($reenable)
    $form.Width = "345"
}
$form.ShowDialog() | out-null
