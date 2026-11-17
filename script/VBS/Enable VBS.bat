@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Defender Remover - 启用 VBS

fltmc >nul 2>&1
if errorlevel 1 (
    echo [错误] 需要管理员权限。
    echo 请从开始菜单启动这个操作，或以管理员身份运行。
    pause
    exit /b 1
)

cls
echo ============================================================
echo   DEFENDER REMOVER - 启用 VBS / CREDENTIAL GUARD
echo ============================================================
echo.
echo 本操作会启用 VBS 和 Credential Guard，准备好 SecConfig.efi，
echo 并安排一次性的 EFI 确认步骤。
echo.
echo 重要：
echo - 如果启用了 BitLocker，请先暂停保护再运行本操作。
echo - 请准备好 BitLocker / 设备加密的恢复密钥。
echo - 下次启动时可能需要固件确认。
echo - 用屏幕上显示的按键确认（不同设备按键不同）。
echo.
choice /C YN /N /M "继续并安排重启？[Y/N]："
if errorlevel 2 goto :Cancelled

set "EFI_GUID={0cb3b571-2f2e-4343-a879-d86a476d7215}"
set "EFI_DRIVE="
set "EFI_MOUNTED="
set "BOOT_ENTRY_CREATED="
set "BOOT_SEQUENCE_SET="
for %%D in (S T U V W X Y Z R Q P O N M L K J I H G F E D) do (
    if not exist "%%D:\." (
        set "EFI_DRIVE=%%D:"
        goto :DriveFound
    )
)

echo [错误] 没有空闲盘符可用于 EFI 分区。
goto :Failed

:DriveFound
if not exist "%WINDIR%\System32\SecConfig.efi" (
    echo [错误] 在 %WINDIR%\System32 里找不到 SecConfig.efi。
    goto :Failed
)

 echo [1/5] 正在配置 VBS 与 Credential Guard 的注册表值…
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "LsaCfgFlags" /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto :Failed

 echo [2/5] 正在把 EFI 系统分区挂载到 %EFI_DRIVE%…
mountvol %EFI_DRIVE% /s
if errorlevel 1 goto :Failed
set "EFI_MOUNTED=1"

if not exist "%EFI_DRIVE%\EFI\Microsoft\Boot" mkdir "%EFI_DRIVE%\EFI\Microsoft\Boot" >nul 2>&1
copy /Y "%WINDIR%\System32\SecConfig.efi" "%EFI_DRIVE%\EFI\Microsoft\Boot\SecConfig.efi" >nul
if errorlevel 1 goto :Failed

 echo [3/5] 正在创建一次性 EFI 启动项…
bcdedit /delete %EFI_GUID% /f >nul 2>&1
bcdedit /create %EFI_GUID% /d "DebugTool" /application osloader >nul
if errorlevel 1 goto :Failed
set "BOOT_ENTRY_CREATED=1"
bcdedit /set %EFI_GUID% path "\EFI\Microsoft\Boot\SecConfig.efi" >nul
if errorlevel 1 goto :Failed
bcdedit /set %EFI_GUID% device partition=%EFI_DRIVE% >nul
if errorlevel 1 goto :Failed
bcdedit /set %EFI_GUID% loadoptions ENABLE-LSA-ISO,ENABLE-VBS >nul
if errorlevel 1 goto :Failed
bcdedit /set vsmlaunchtype Auto >nul
if errorlevel 1 goto :Failed
bcdedit /set {bootmgr} bootsequence %EFI_GUID% >nul
if errorlevel 1 goto :Failed
set "BOOT_SEQUENCE_SET=1"

 echo [4/5] 正在卸载 EFI 系统分区…
mountvol %EFI_DRIVE% /d
if errorlevel 1 goto :Failed
set "EFI_MOUNTED="

 echo [5/5] 配置完成。
echo 电脑将在 15 秒后重启。
echo 启动过程中如果提示确认固件改动，请同意。
shutdown /r /t 15 /c "Defender Remover: VBS and Credential Guard activation is pending EFI confirmation."
exit /b 0

:Cancelled
echo 操作已取消，没有做任何改动。
exit /b 0

:Failed
if defined EFI_MOUNTED mountvol %EFI_DRIVE% /d >nul 2>&1
if defined BOOT_SEQUENCE_SET bcdedit /deletevalue {bootmgr} bootsequence >nul 2>&1
if defined BOOT_ENTRY_CREATED bcdedit /delete %EFI_GUID% /f >nul 2>&1
echo.
echo [错误] 操作没有完成，请查看上面的提示。
echo 如果注册表设置已经写入，重试前可能需要先检查一遍。
pause
exit /b 1
