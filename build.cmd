cd /d %~dp0
powershell Import-Module ps2exe; ps2exe avysis.ps1 -noConsole -iconFile avysissmall.ico
powershell Import-Module ps2exe; ps2exe avysismitm.ps1 -noConsole
iscc setup.iss
