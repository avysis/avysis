$falsePositives = @("D41D8CD98F00B204E9800998ECF8427E")

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text | where { $_.id -eq "1" }).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text | where { $_.id -eq "2" }).AppendChild($RawXml.CreateTextNode($ToastText)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "Avysis"
    $Toast.Group = "Avysis"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}


$hash = (Get-FileHash -Path $args[0] -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
if ($falsePositives.Contains($hash)) {
    exit
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
    Show-Notification -ToastTitle "We found a virus" -ToastText "We found a virus on your PC, so we prevented it from running."
}
else {
    $filename = $args[0]
    if ($args.count -gt 1) {
        $arguments = $args[1..$args.count]
        Start-Process $filename -ArgumentList $arguments
    }
    elseif ($args.count -eq 1) {
        Start-Process $filename
    }
}