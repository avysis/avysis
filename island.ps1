Add-Type -AssemblyName System.Windows.Forms, PresentationCore, PresentationFramework
Function Get-Folder($initialDirectory="")

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
        return $folder
    }
    else
    {
        return $null
    }
}
$form = New-Object Windows.Forms.Form
$form.Text = "Island"
$form.Width = "390"
$form.Height = "75"
$form.FormBorderStyle = 'Fixed3D'
$form.MaximizeBox = $false
$form.TopMost = $True
$base64IconString = "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"
$iconimageBytes = [Convert]::FromBase64String($base64IconString)
$ims = New-Object IO.MemoryStream($iconimageBytes, 0, $iconimageBytes.Length)
$ims.Write($iconimageBytes, 0, $iconimageBytes.Length);
$alkIcon = [System.Drawing.Image]::FromStream($ims, $true)
$form.Icon = [System.Drawing.Icon]::FromHandle((new-object System.Drawing.Bitmap -argument $ims).GetHIcon())
$scan = New-Object Windows.Forms.Button
$scan.text = "Scan"
$scan.Location = New-Object Drawing.Point(10, 10)
$scan.Add_Click({
    $folder = @((New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path, (New-Object -ComObject Shell.Application).NameSpace('shell:start menu').Self.Path, $env:TEMP)
    $items = Get-ChildItem $folder -Recurse -ErrorAction SilentlyContinue | Where { ! $_.PSIsContainer }
    $completed = 0
    $has_threat = $false
    $items | % {
        $completed += 1
        $percent = [Math]::Round(($completed / ($items | Measure-Object).count * 100))
        $name = $_.Name
        Write-Progress -Activity "Scan" -Status "Island is scanning your computer. This may take a while. Scanning file $name. $percent% complete." -PercentComplete $percent
        $hash = (Get-FileHash -Path $_.FullName -Algorithm MD5).Hash
        $api = Invoke-RestMethod "https://urlhaus-api.abuse.ch/v1/payload/" -Method Post -Body "md5_hash=$hash"
        if ($api.query_status -eq "ok") {
            $has_threat = $true
            $signature = $api.signature
            if ($signature -eq $null) {$signature = "Malware"}
            $basename = (Get-Item $_.FullName).Name
            $actualBasename = (Get-Item $_.FullName).Basename
            $fullname = $_.FullName
            $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?",$fullname,4,48)
            if ($msgbox -eq 6) {
                start-process powershell.exe -ArgumentList "del '$fullname' -Force" -Verb RunAs
            }
        }
    }
    Write-Progress -Activity "Scan" -Status "Ready" -Completed
    if (!($has_threat)) {
        [System.Windows.MessageBox]::Show("No threats!","No threats!",0,64)
    }
})
$scanfldr = New-Object Windows.Forms.Button
$scanfldr.text = "Scan folder"
$scanfldr.Location = New-Object Drawing.Point(90, 10)
$scanfldr.Add_Click({
    $folder = Get-Folder
    if ($folder -eq $null) {return}
    $items = Get-ChildItem $folder -Recurse | Where { ! $_.PSIsContainer }
    $completed = 0
    $has_threat = $false
    $items | % {
        $completed += 1
        $percent = [Math]::Round(($completed / ($items | Measure-Object).count * 100))
        $name = $_.Name
        Write-Progress -Activity "Scan a folder" -Status "Island is scanning a folder. This may take a while. Scanning file $name. $percent% complete." -PercentComplete $percent
        $hash = (Get-FileHash -Path $_.FullName -Algorithm MD5).Hash
        $api = Invoke-RestMethod "https://urlhaus-api.abuse.ch/v1/payload/" -Method Post -Body "md5_hash=$hash"
        if ($api.query_status -eq "ok") {
            $has_threat = $true
            $signature = $api.signature
            if ($signature -eq $null) {$signature = "Malware"}
            $basename = (Get-Item $_.FullName).Name
            $actualBasename = (Get-Item $_.FullName).Basename
            $fullname = $_.FullName
            $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?",$_,4,48)
            if ($msgbox -eq 6) {
                start-process powershell.exe -ArgumentList "del '$fullname' -Force" -Verb RunAs
            }
        }
    }
    Write-Progress -Activity "Scan a folder" -Status "Ready" -Completed
    if (!($has_threat)) {
        [System.Windows.MessageBox]::Show("No threats!","No threats!",0,64)
    }
})
$scanfile = New-Object Windows.Forms.Button
$scanfile.text = "Scan file"
$scanfile.Location = New-Object Drawing.Point(170, 10)
$scanfile.Add_Click({
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        InitialDirectory = [Environment]::GetFolderPath('Desktop') 
        Filter = 'All files|*'
    }
    $null = $FileBrowser.ShowDialog()
    if (!($FileBrowser.FileName)) {return}
    $hash = (Get-FileHash -Path $FileBrowser.FileName -Algorithm MD5).Hash
    $api = Invoke-RestMethod "https://urlhaus-api.abuse.ch/v1/payload/" -Method Post -Body "md5_hash=$hash"
    if ($api.query_status -eq "ok") {
        $signature = $api.signature
        if ($signature -eq $null) {$signature = "Malware"}
        $basename = $FileBrowser.SafeFileName
        $actualBasename = (Get-Item $FileBrowser.FileName).Basename
        $msgbox = [System.Windows.MessageBox]::Show("$basename is infected with $signature. Would you like to remove it from your computer?",$_,4,48)
        if ($msgbox -eq 6) {
            get-process $actualBasename | stop-process
            start-process powershell.exe -ArgumentList "del '$_' -Force" -Verb RunAs
        }
    } else {
        [System.Windows.MessageBox]::Show("No threats!","No threats!",0,64)
    }
})
$tempdisable = New-Object Windows.Forms.Button
$tempdisable.text = "Disable temporarily"
$tempdisable.Location = New-Object Drawing.Point(250, 10)
$tempdisable.Width = 120
$tempdisable.Add_Click({
    Get-Process islandbg | Stop-Process
    [System.Windows.MessageBox]::Show("Successful. We disabled real-time protection until the next logon.","Success",0,64)
})
$form.controls.add($scan)
$form.controls.add($scanfldr)
$form.controls.add($scanfile)
$form.controls.add($tempdisable)
$form.ShowDialog() | out-null