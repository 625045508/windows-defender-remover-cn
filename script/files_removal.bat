@echo off
chcp 65001 >nul
setlocal EnableExtensions
title Defender Remover 13.1 - 安全删除文件
set "SCRIPT=%~dp0Script_Run.ps1"
if not exist "%SCRIPT%" (
    echo [错误] 找不到与本启动器同目录的 Script_Run.ps1。
    pause
    exit /b 1
)
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL%" set "POWERSHELL=powershell.exe"
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" s
exit /b %errorlevel%
