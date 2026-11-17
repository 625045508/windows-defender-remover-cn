@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Windows Defender Remover 验证
color 0A

:: =========================================================
:: Windows Defender Remover - 验证脚本
:: ---------------------------------------------------------
:: 用途：
::   检查运行本工具并重启之后，主要的 Windows Defender /
::   Windows 安全中心组件是否看起来已经被删除。
::
::
:: 说明：
::   - 以管理员身份运行
::   - 在最后一次重启之后再运行
::   - 本脚本不会删除任何东西
::   - 只做检查并报告结果
:: =========================================================

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo [错误] 请以管理员身份运行本文件。
    echo.
    pause
    exit /b 1
)

set /a OK=0
set /a WARN=0
set /a KO=0

cls
echo =========================================================
echo   WINDOWS DEFENDER REMOVER - 验证
echo =========================================================
echo.
echo 请在最后一次重启之后再运行本检查。
echo.

call :section "1) 应该已被删除的残留文件夹"
call :check_folder_missing "C:\ProgramData\Microsoft\Windows Defender" "ProgramData\Microsoft\Windows Defender"
call :check_folder_missing "C:\Program Files\Windows Defender" "Program Files\Windows Defender"
call :check_folder_missing "C:\Program Files (x86)\Windows Defender" "Program Files (x86)\Windows Defender"
call :check_folder_missing "C:\Program Files\Windows Defender Advanced Threat Protection" "Program Files\Windows Defender Advanced Threat Protection"

call :section "2) 本工具应该删除的服务 / 驱动"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" "WinDefend 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" "WdFilter 驱动"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" "WdBoot 驱动"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" "WdNisSvc 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv" "WdNisDrv 驱动"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\wscsvc" "wscsvc 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" "SecurityHealthService"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\SgrmBroker" "SgrmBroker 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\SgrmAgent" "SgrmAgent 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\MsSecCore" "MsSecCore 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\MsSecFlt" "MsSecFlt 驱动"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\MsSecWfp" "MsSecWfp 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\webthreatdefsvc" "webthreatdefsvc 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\webthreatdefusersvc" "webthreatdefusersvc 服务"
call :check_reg_missing "HKLM\SYSTEM\CurrentControlSet\Services\whesvc" "whesvc 服务"

call :section "3) Windows 安全中心（SecHealthUI）"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$a = Get-AppxPackage -AllUsers *SecHealthUI* -ErrorAction SilentlyContinue; $p = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; $found = $false; foreach ($item in $p) { if ($item.PackageName -like '*SecHealthUI*') { $found = $true } }; if (($null -ne $a) -or $found) { exit 1 } else { exit 0 }"
if errorlevel 1 (
    call :ko "SecHealthUI 仍然存在"
) else (
    call :ok "SecHealthUI 已不存在"
)

call :section "4) Windows Defender 计划任务"
schtasks /query /fo list /v 2>nul | findstr /I /C:"\Microsoft\Windows\Windows Defender\" >nul
if errorlevel 1 (
    call :ok "没有发现 Windows Defender 计划任务"
) else (
    call :warn "Windows Defender 计划任务仍然存在"
)

call :section "5) 相关设置一致性检查（不一致只记警告）"
call :check_reg_contains_warn "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "SettingsPageVisibility" "hide:windowsdefender;" "Windows 安全中心页面已隐藏"
call :check_reg_contains_warn "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" "off" "资源管理器 SmartScreen 已设为关闭"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" "0x0" "EnableSmartScreen = 0"
call :check_reg_contains_warn "HKLM\SOFTWARE\Microsoft\Windows Security Health\Platform" "Registered" "0x0" "Windows 安全健康状态 Registered = 0"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" "0x1" "DisableAntiSpyware = 1"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" "0x1" "DisableRealtimeMonitoring = 1"
call :check_reg_contains_warn "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpynetReporting" "0x0" "SpynetReporting = 0"

echo.
echo =========================================================
echo                         汇总
echo =========================================================
echo 通过 : %OK%
echo 警告 : %WARN%
echo 问题 : %KO%
echo.

if %KO% EQU 0 (
    if %WARN% EQU 0 (
        schtasks /delete /tn "DefenderRemoverVerify" /f >nul 2>&1
        echo 最终结果：看起来一切都已正确删除。
    ) else (
        schtasks /delete /tn "DefenderRemoverVerify" /f >nul 2>&1
        echo 最终结果：删除应该成功了，但有几项次要检查需要看一下。
    )
) else (
    schtasks /delete /tn "DefenderRemoverVerify" /f >nul 2>&1
    echo 最终结果：仍有东西存在，或没有被完全删除。
)

echo.
echo 按任意键关闭…
pause >nul
exit /b

:section
echo.
echo ---------------------------------------------------------
echo %~1
echo ---------------------------------------------------------
exit /b

:check_folder_missing
if exist "%~1" (
    call :ko "%~2 存在"
) else (
    call :ok "%~2 不存在"
)
exit /b

:check_reg_missing
reg query "%~1" >nul 2>&1
if errorlevel 1 (
    call :ok "%~2 不存在"
) else (
    call :ko "%~2 存在"
)
exit /b

:check_reg_contains_warn
reg query "%~1" /v "%~2" 2>nul | findstr /I /C:"%~3" >nul
if errorlevel 1 (
    call :warn "%~4 未找到 / 与预期不同"
) else (
    call :ok "%~4"
)
exit /b

:ok
set /a OK+=1
echo [通过] %~1
exit /b

:warn
set /a WARN+=1
echo [警告] %~1
exit /b

:ko
set /a KO+=1
echo [问题] %~1
exit /b