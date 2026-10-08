@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Native-Speed.ps1" %*
set "locus_exit=%errorlevel%"
pause
exit /b %locus_exit%
