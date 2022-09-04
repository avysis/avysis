![](island.png) [beta]

Island is a small antivirus built with PowerShell. It uses the [URLHaus API](https://urlhaus-api.abuse.ch/), which is really useful (doesn't use a key, no rate-limit). It's only recommended for systems that don't support Windows Defender (like the recent tiny10 builds).

## How to install

Currently, the installation process is to run these:

- `ps2exe island.ps1 -noConsole`
- `ps2exe islandbg.ps1 -noConsole`
- Place islandbg.exe in your startup folder.
- Create a shortcut to island.exe somewhere.
