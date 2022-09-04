cd %~dp0
powershell ps2exe island.ps1 -noConsole -iconFile islandsmall.ico
powershell ps2exe islandbg.ps1 -noConsole -iconFile islandsmall.ico
iscc setup.iss