@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\export.ps1" %*
if errorlevel 1 pause
