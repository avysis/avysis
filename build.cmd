cd %~dp0
powershell Import-Module ps2exe; ps2exe island.ps1 -noConsole -iconFile islandsmall.ico
powershell Import-Module ps2exe; ps2exe islandbg.ps1 -noConsole -iconFile islandsmall.ico
iscc setup.iss
