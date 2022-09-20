Add-Type -AssemblyName System.Windows.Forms, PresentationCore, PresentationFramework

function Test-RegistryValue {

    param (
    
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,
    
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )
    
    try {
    
        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
    }
    
    catch {
    
        return $false
    
    }
    
}

$protected = (Test-RegistryValue -Path "HKLM:\SOFTWARE\Avysis" -Value "Unprotected")
$falsePositives = @("D41D8CD98F00B204E9800998ECF8427E")
[Net.ServicePointManager]::MaxServicePointIdleTime = 3000
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

function Show-RemoveVirusDialog([array]$viruses) {
    $global:viruses = $viruses
    $virusdialog = New-Object Windows.Forms.Form
    $virusdialog.Text = "Remove viruses"
    $virusdialog.Width = "400"
    $virusdialog.Height = "430"
    $virusdialog.FormBorderStyle = 'Fixed3D'
    $virusdialog.MaximizeBox = $false
    $virusdialog.TopMost = $True
    $virusdialog.ShowIcon = $false
    $threatsfound = New-Object Windows.Forms.Label
    $threatsfound.Text = "Viruses were found. You may want to remove all or some of these viruses."
    $threatsfound.AutoSize = $True
    $threatsfound.Location = New-Object Drawing.Point(10, 10)
    $virusdialog.Controls.Add($threatsfound)
    $virusselect = New-Object Windows.Forms.ListBox
    $virusselect.Location = New-Object Drawing.Point(10, 30)
    $virusselect.Width = "370"
    $virusselect.Height = "320"
    $global:viruses | % { $virusselect.Items.Add($_) } | out-null
    $virusdialog.Controls.add($virusselect)
    $delete = New-Object Windows.Forms.Button
    $delete.Text = "Delete"
    $delete.Location = New-Object Drawing.Point(10, 360)
    $delete.Add_Click({
            $item = $virusselect.SelectedItem
            if (! $item) {
                return
            }
            $actualBasename = (Get-Item $item).BaseName
            $fullname = $item
            start-process powershell.exe -ArgumentList "get-process $actualBasename | stop-process; del '$fullname' -Force" -Verb RunAs
            $virusselect.items.Remove($item)
            $newViruses = @()
            foreach ($virus in $global:viruses) {
                if ($virus -ne $item) {
                    $newViruses += $virus
                }
            }
            $global:viruses = $newViruses
        })
    $deleteAll = New-Object Windows.Forms.Button
    $deleteAll.Text = "Delete all"
    $deleteAll.Location = New-Object Drawing.Point(90, 360)
    $deleteAll.Add_Click({
            $command = ""
            $global:viruses | % {
                $item = $_
                $actualBasename = (Get-Item $item).BaseName
                $fullname = $item
                $command += "; get-process $actualBasename | stop-process; del '$fullname' -Force"
            }
            start-process powershell.exe -ArgumentList $command -Verb RunAs
            $virusselect.Items.Clear()
            $virusdialog.close()
        })
    $virusdialog.Controls.add($delete)
    $virusdialog.Controls.add($deleteAll)
    $virusdialog.ShowDialog() | out-null
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
        $items = Get-ChildItem $folder -Recurse -ErrorAction SilentlyContinue | Where { ! $_.PSIsContainer } | select-object -expandproperty fullname
        $items = $items + (Get-Process | Select-Object -ExpandProperty Path | Sort-Object | Get-Unique)
        $items = $items | % {
            Get-Item $_
        }
        $completed = 0
        $has_threat = $false
        $viruses = @()
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
                $viruses += $_.FullName
            }
        }
        Write-Progress -Activity "Scan" -Status "Ready" -Completed
        if ($viruses.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No threats!", "No threats!", 0, 64)
        }
        else {
            Show-RemoveVirusDialog -viruses $viruses
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
        $viruses = @()
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
                $viruses += $_.FullName
            }
        }
        Write-Progress -Activity "Scan a folder" -Status "Ready" -Completed
        if ($viruses.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No threats!", "No threats!", 0, 64)
        }
        else {
            Show-RemoveVirusDialog -viruses $viruses
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
            Show-RemoveVirusDialog -viruses @($FileBrowser.FileName)
        }
        else {
            [System.Windows.MessageBox]::Show("No threats!", "No threats!", 0, 64)
        }
    })
$disable = New-Object Windows.Forms.Button
$disable.text = "Disable"
$disable.Location = New-Object Drawing.Point(250, 40)
$disable.Add_Click({
        reg.exe add HKCR\exefile\shell\open\command /ve /d "`"%0`" %*" /f | Out-Null
        reg.exe add HKLM\Software\Avysis /v Unprotected | Out-Null
        $prtext.Text = "You're not protected"
        $prtext.ForeColor = "red"
        $form.controls.remove($disable)
        $form.controls.add($reenable)
        $form.Width = "345"
    })
$reenable = New-Object Windows.Forms.Button
$reenable.text = "Re-enable"
$reenable.Location = New-Object Drawing.Point(250, 40)
$reenable.Add_Click({
        $installPath = (Get-ItemProperty HKLM:\Software\Avysis -Name "InstallPath").InstallPath
        reg.exe add HKCR\exefile\shell\open\command /ve /d "$installPath\avysismitm.exe `"%1`" %*" /f | Out-Null
        reg.exe delete HKLM\Software\Avysis /v Unprotected /f | Out-Null
        $prtext.Text = "You're protected"
        $prtext.ForeColor = "green"
        $form.controls.add($disable)
        $form.controls.remove($reenable)
        $form.Width = "390"
    })
$form.controls.add($prtext)
$form.controls.add($scan)
$form.controls.add($scanfldr)
$form.controls.add($scanfile)
$form.controls.add($disable)
if (! $protected) {
    $form.controls.remove($disable)
    $form.controls.add($reenable)
    $form.Width = "345"
}
$form.ShowDialog() | out-null
