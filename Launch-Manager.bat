@echo off
title pfBlockerNG Manager v3.5
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0pfBlockerNG-Manager.ps1"
pause
