cd %~dp0
powershell Import-Module ps2exe; ps2exe avysis.ps1 -noConsole -iconFile avysissmall.ico
powershell Import-Module ps2exe; ps2exe avysisbg.ps1 -noConsole -iconFile avysissmall.ico
iscc setup.iss
