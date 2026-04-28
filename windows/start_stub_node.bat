@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0run_node.ps1" -RepoPath "C:\trade-signal-bot" -HostAddress "0.0.0.0" -Port 8008
pause
