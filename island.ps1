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
    }
    return $folder
}
$form = New-Object Windows.Forms.Form
$form.Text = "Island"
$form.Width = "310"
$form.Height = "75"
$form.FormBorderStyle = 'Fixed3D'
$form.MaximizeBox = $false
$scanfldr = New-Object Windows.Forms.Button
$scanfldr.text = "Scan folder"
$scanfldr.Location = New-Object Drawing.Point(10, 10)
$scanfldr.Add_Click({
    $folder = Get-Folder
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
$scanfile.Location = New-Object Drawing.Point(90, 10)
$scanfile.Add_Click({
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        InitialDirectory = [Environment]::GetFolderPath('Desktop') 
        Filter = 'All files|*'
    }
    $null = $FileBrowser.ShowDialog()
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
$tempdisable.Location = New-Object Drawing.Point(170, 10)
$tempdisable.Width = 120
$tempdisable.Add_Click({
    Get-Process islandbg | Stop-Process
    [System.Windows.MessageBox]::Show("We're sorry to see you go! We disabled it until the next boot.","Success",0,64)
})
$form.controls.add($scanfldr)
$form.controls.add($scanfile)
$form.controls.add($tempdisable)
$form.ShowDialog() | out-null