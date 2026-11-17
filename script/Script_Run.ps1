# Windows Defender Remover - PowerShell version
$defenderremoverver = "13.1"

# -----------------------------------------------------------------------------
# Admin rights check and elevation
# -----------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "正在请求管理员权限…" -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($args -join ' ')"
    exit
}

Set-Location $PSScriptRoot

# Kill processes that may interfere
Stop-Process -Name smartscreen -Force -ErrorAction SilentlyContinue

# -----------------------------------------------------------------------------
# Persistent Start Menu shortcuts and backup/restore engine
# -----------------------------------------------------------------------------
. (Join-Path $PSScriptRoot 'DefenderBackupRestore.ps1')

function Install-DefenderStartMenuShortcuts {
    $programDataRoot = Join-Path $env:ProgramData 'Gallery Inc\Defender Remover'
    $vbsInstallDir = Join-Path $programDataRoot 'VBS'
    $programsDir = [Environment]::GetFolderPath('CommonPrograms')
    if ([string]::IsNullOrWhiteSpace($programsDir)) {
        $programsDir = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
    }
    $shortcutDir = Join-Path $programsDir 'Defender Remover'

    $requiredFiles = @(
        @{ Source = (Join-Path $PSScriptRoot 'VBS\Enable VBS.bat'); Destination = (Join-Path $vbsInstallDir 'Enable VBS.bat') },
        @{ Source = (Join-Path $PSScriptRoot 'VBS\Disable VBS.bat'); Destination = (Join-Path $vbsInstallDir 'Disable VBS.bat') },
        @{ Source = (Join-Path $PSScriptRoot 'VBS\Run-VBSAction.ps1'); Destination = (Join-Path $vbsInstallDir 'Run-VBSAction.ps1') },
        @{ Source = (Join-Path $PSScriptRoot 'DefenderBackupRestore.ps1'); Destination = (Join-Path $programDataRoot 'DefenderBackupRestore.ps1') },
        @{ Source = (Join-Path $PSScriptRoot 'Restore-Defender.ps1'); Destination = (Join-Path $programDataRoot 'Restore-Defender.ps1') },
        @{ Source = (Join-Path $PSScriptRoot 'PowerRun.exe'); Destination = (Join-Path $programDataRoot 'PowerRun.exe') }
    )

    foreach ($item in $requiredFiles) {
        if (-not (Test-Path -LiteralPath $item.Source -PathType Leaf)) {
            throw "缺少必需的支持文件：$($item.Source)"
        }
    }

    New-Item -ItemType Directory -Path $vbsInstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path $shortcutDir -Force | Out-Null
    foreach ($item in $requiredFiles) {
        Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Force
    }

    $powershellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (-not (Test-Path -LiteralPath $powershellExe)) { $powershellExe = 'powershell.exe' }
    $vbsLauncherPath = Join-Path $vbsInstallDir 'Run-VBSAction.ps1'
    $restoreLauncherPath = Join-Path $programDataRoot 'Restore-Defender.ps1'
    $shell = New-Object -ComObject WScript.Shell

    $shortcuts = @(
        @{ Name = '启用 VBS'; Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$vbsLauncherPath`" -Action Enable"; Description = '启用基于虚拟化的安全性（VBS）与 Credential Guard'; Icon = "$env:SystemRoot\System32\shell32.dll,44" },
        @{ Name = '关闭 VBS'; Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$vbsLauncherPath`" -Action Disable"; Description = '关闭基于虚拟化的安全性（VBS）与 Credential Guard'; Icon = "$env:SystemRoot\System32\shell32.dll,44" },
        @{ Name = '恢复 Defender'; Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$restoreLauncherPath`""; Description = '从备份快照还原 Defender 文件与注册表；Windows 安全中心可能无法还原'; Icon = "$env:SystemRoot\System32\imageres.dll,73" }
    )

    foreach ($item in $shortcuts) {
        $shortcutPath = Join-Path $shortcutDir ($item.Name + '.lnk')
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $powershellExe
        $shortcut.Arguments = $item.Arguments
        $shortcut.WorkingDirectory = $programDataRoot
        $shortcut.Description = $item.Description
        $shortcut.IconLocation = $item.Icon
        $shortcut.Save()
    }
}

# -----------------------------------------------------------------------------
# Function definitions
# -----------------------------------------------------------------------------
function Setup-Verification {
    Write-Host "正在准备重启后的验证脚本…" -ForegroundColor Cyan
    $targetDir = "C:\ProgramData\Gallery Inc\Defender Remover"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # Conținutul fișierului batch (verify.bat)
    $batchScript = @'
@echo off
chcp 65001 >nul
@echo off
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
'@
    $batchPath = "$targetDir\verify.bat"
    $batchScript | Out-File -FilePath $batchPath -Encoding Default -Force

    $taskName = "DefenderRemoverVerify"
    $currentUser = "$env:USERDOMAIN\$env:USERNAME"
     try {
        # Action: run cmd.exe /c with the batch file path
        $action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument "/c `"$batchPath`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -RunLevel Highest

        # Register the task (overwrite if exists)
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force -ErrorAction Stop
        Write-Host "计划任务创建成功（ScheduledTasks 模块）。" -ForegroundColor Green
    } catch {
        Write-Host "创建计划任务出错：$_" -ForegroundColor Red
        Write-Host "改用 schtasks 重试…" -ForegroundColor Yellow
        $cmdLine = "cmd.exe /c `"$batchPath`""
        $escapedCmd = $cmdLine -replace '"', '\"'
        $output = schtasks /Create /TN $taskName /TR "`"$escapedCmd`"" /SC ONLOGON /RL HIGHEST /RU "$currentUser" /F 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "创建计划任务出错（schtasks）：$output" -ForegroundColor Red
        } else {
            Write-Host "计划任务创建成功（schtasks）。" -ForegroundColor Green
        }
    }
}

function Remove-Files {
    Write-Host '正在删除 Defender 文件…' -ForegroundColor Cyan
    $session = New-DefenderBackupSession -RemovalMode 'FilesOnly'
    $folders = @(
        'C:\ProgramData\Microsoft\Windows Defender',
        'C:\Program Files\Windows Defender',
        'C:\Program Files (x86)\Windows Defender',
        'C:\Program Files\Windows Defender Advanced Threat Protection'
    )

    foreach ($folder in $folders) {
        Backup-AndRemoveDefenderDirectory -Session $session -SourcePath $folder | Out-Null
    }

    Complete-DefenderBackupSession -Session $session -RebootRecommended $true
    Write-Host "备份快照：$($session.Root)" -ForegroundColor Green
    Write-Host '文件操作完成后建议重启。' -ForegroundColor Yellow
    Read-Host '按回车键关闭'
    exit
}

function Test-WindowsSecurityAppPresent {
    try {
        $installed = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*SecHealthUI*' -or $_.PackageFullName -like '*SecHealthUI*' })
        $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like '*SecHealthUI*' })
        return (($installed.Count -gt 0) -or ($provisioned.Count -gt 0))
    } catch {
        return $true
    }
}

function Confirm-IrreversibleSecurityAppRemoval {
    Write-Host ''
    Write-Host '!!! 这个操作无法撤销 !!!' -ForegroundColor Red
    Write-Host 'Windows 安全中心（SecHealthUI）应用包会为所有用户删除，并从系统预置中移除（取消预配）。' -ForegroundColor Yellow
    Write-Host '“恢复 Defender”能还原已备份的文件和注册表，但无法重新安装这个应用包。' -ForegroundColor Yellow
    Write-Host '备份快照里会明确标记该应用包“不可恢复”。' -ForegroundColor Yellow
    Write-Host ''
    $confirmation = Read-Host '输入“删除安全中心”继续'
    return ($confirmation -ceq '删除安全中心')
}

function Remove-Defender {
    if (-not (Confirm-IrreversibleSecurityAppRemoval)) {
        Write-Host '已取消删除，Defender 组件没有任何改动。' -ForegroundColor Yellow
        return
    }

    $session = New-DefenderBackupSession -RemovalMode 'DefenderAndWindowsSecurityApp' -WindowsSecurityAppRequested

    Write-Host '正在删除 Windows 安全中心 UWP 应用（这一步本工具无法恢复）…' -ForegroundColor Cyan
    try {
        $appWasPresentBeforeRemoval = Test-WindowsSecurityAppPresent
        $session.Manifest.WindowsSecurityApp.DetectedBefore = [bool]$appWasPresentBeforeRemoval
        Write-DefenderManifest -Session $session
        $appRemovalScript = Join-Path $PSScriptRoot 'RemoveSecHealthApp.ps1'
        $powerRun = Join-Path $PSScriptRoot 'PowerRun.exe'
        $appPowerShell = if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { Join-Path $env:windir 'Sysnative\WindowsPowerShell\v1.0\powershell.exe' } else { Join-Path $env:windir 'System32\WindowsPowerShell\v1.0\powershell.exe' }
        if (-not (Test-Path -LiteralPath $appPowerShell)) { $appPowerShell = 'powershell.exe' }
        if (Test-Path -LiteralPath $powerRun -PathType Leaf) {
            $arguments = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}"' -f $appPowerShell, $appRemovalScript
            Start-Process -FilePath $powerRun -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop | Out-Null
        } else {
            Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$appRemovalScript`"" -Verb RunAs -Wait -PassThru -ErrorAction Stop | Out-Null
        }
        if (Test-WindowsSecurityAppPresent) {
            $session.Manifest.WindowsSecurityApp.Status = 'RemovalFailedOrStillPresent'
            $session.Manifest.WindowsSecurityApp.Reason = '已请求删除，但仍检测到该 AppX 包或预置包。'
            Add-DefenderManifestWarning -Session $session -Message '无法确认 Windows 安全中心是否已删除。'
            Write-Host '警告：仍然检测到 Windows 安全中心，请检查 AppX 删除过程的输出。' -ForegroundColor Yellow
        } elseif ($appWasPresentBeforeRemoval) {
            $session.Manifest.WindowsSecurityApp.Status = 'RemovedNotRestorable'
            $session.Manifest.WindowsSecurityApp.Reason = '删除前存在 SecHealthUI，现在已不存在。“恢复 Defender”不会尝试重装这个包。'
            Write-Host '已确认 Windows 安全中心被删除。该组件无法通过“恢复 Defender”还原。' -ForegroundColor Yellow
        } else {
            $session.Manifest.WindowsSecurityApp.Status = 'AlreadyAbsent'
            $session.Manifest.WindowsSecurityApp.Reason = '删除前没有检测到 SecHealthUI，因此没有可备份或恢复的 AppX 包。'
            Write-Host 'Windows 安全中心本来就不存在，无需删除 AppX 包。' -ForegroundColor Yellow
        }
        Write-DefenderManifest -Session $session
    } catch {
        $session.Manifest.WindowsSecurityApp.Status = 'RemovalFailed'
        $session.Manifest.WindowsSecurityApp.Reason = $_.Exception.Message
        Add-DefenderManifestWarning -Session $session -Message "删除 Windows 安全中心失败：$($_.Exception.Message)"
        Write-Host "删除 Windows 安全中心时出错：$_" -ForegroundColor Red
    }

    Write-Host '正在备份并注销 Windows Defender 注册表组件…' -ForegroundColor Cyan
    $powerRunPath = Join-Path $PSScriptRoot 'PowerRun.exe'
    $regFiles = @(
        Get-ChildItem -Path (Join-Path $PSScriptRoot 'Remove_Defender') -Filter '*.reg' -File -Recurse -ErrorAction SilentlyContinue
        Get-ChildItem -Path (Join-Path $PSScriptRoot 'Remove_SecurityComp') -Filter '*.reg' -File -Recurse -ErrorAction SilentlyContinue
    )
    foreach ($regFile in $regFiles) {
        Invoke-DefenderRegistryFileWithBackup -Session $session -RegFile $regFile.FullName -PowerRunPath $powerRunPath | Out-Null
    }

    Write-Host '正在备份并删除 SmartScreen 文件…' -ForegroundColor Cyan
    $smartscreenFiles = @(
        "$env:windir\System32\smartscreen.exe",
        "$env:windir\System32\smartscreen.dll",
        "$env:windir\System32\smartscreenps.dll"
    )
    foreach ($file in $smartscreenFiles) {
        Backup-AndRemoveDefenderFile -Session $session -SourcePath $file | Out-Null
    }

    Complete-DefenderBackupSession -Session $session -RebootRecommended $true
    Write-Host "备份快照已保存：$($session.Root)" -ForegroundColor Green
    Setup-Verification
    Write-Host '10 秒后重启 Windows…' -ForegroundColor Yellow
    shutdown /r /f /t 10
    exit
}

function Remove-Antivirus {
    Write-Host '正在删除 Windows Defender 杀毒组件…' -ForegroundColor Cyan
    $session = New-DefenderBackupSession -RemovalMode 'AntivirusOnly'
    $powerRunPath = Join-Path $PSScriptRoot 'PowerRun.exe'
    $regFiles = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Remove_Defender') -Filter '*.reg' -File -Recurse -ErrorAction SilentlyContinue)
    foreach ($regFile in $regFiles) {
        Invoke-DefenderRegistryFileWithBackup -Session $session -RegFile $regFile.FullName -PowerRunPath $powerRunPath | Out-Null
    }

    Complete-DefenderBackupSession -Session $session -RebootRecommended $true
    Write-Host "备份快照已保存：$($session.Root)" -ForegroundColor Green
    Setup-Verification
    Write-Host '5 分钟后重启 Windows…' -ForegroundColor Yellow
    Start-Sleep -Seconds 300
    shutdown /r /f /t 10
    exit
}

# Install/update the Defender Remover shortcuts in the all-users Start Menu.
try {
    Install-DefenderStartMenuShortcuts
} catch {
    Write-Warning "无法创建 Defender Remover 的开始菜单快捷方式：$_"
}

# -----------------------------------------------------------------------------
# Argument / menu handling
# -----------------------------------------------------------------------------
$arg = $args[0]
if ($arg -eq 'y') {
    Remove-Defender
} elseif ($arg -eq 'a') {
    Remove-Antivirus
} elseif ($arg -eq 's') {
    Remove-Files
} else {
    # Display menu. Use Console I/O for the final prompt because Read-Host can
    # render out of order in some PS2EXE -ConHost builds.
    Clear-Host
    $runtimeProcesses = @(Get-DefenderRuntimeProcessSnapshot)
    if ($runtimeProcesses.Count -gt 0) {
        Write-Host '[提示] 检测到与 Defender 相关的进程：' -ForegroundColor Yellow
        foreach ($runtimeProcess in $runtimeProcesses) {
            Write-Host ("  {0}.exe（PID {1}）" -f $runtimeProcess.Name, $runtimeProcess.Pid) -ForegroundColor Yellow
        }
        Write-Host '本工具不会结束这些进程，也不会修改它们的安全令牌。' -ForegroundColor Yellow
        Write-Host ''
    } else {
        Write-Host 'Defender 进程检查：启动时没有检测到 Defender 核心进程。' -ForegroundColor DarkGray
        Write-Host ''
    }
    Write-Host "------ Defender Remover 脚本，版本 $defenderremoverver ------" -ForegroundColor Green
    Write-Host ""
    Write-Host "要删除 Windows Defender 及其相关组件吗？删除完成后需要重启电脑。"
    Write-Host "文件和注册表的改动会先做备份快照。Windows 安全中心一旦删除就无法恢复。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[Y] 删除 Windows Defender 杀毒 + Windows 安全中心（安全中心删除后不可恢复）" -ForegroundColor Yellow
    Write-Host "[A] 只删除 Windows Defender 杀毒组件（保留 Windows 安全中心）"
    Write-Host "[S] 删除 Defender 残留文件（适合之前已经删掉杀毒的机器）"
    Write-Host ""
    [Console]::Out.Flush()
    [Console]::Write('请输入选项（Y/A/S）：')
    [Console]::Out.Flush()
    $choice = [Console]::ReadLine()
    if ($null -eq $choice) { $choice = '' }
    switch ($choice.Trim().ToUpperInvariant()) {
        'Y' { Remove-Defender }
        'A' { Remove-Antivirus }
        'S' { Remove-Files }
        default {
            Write-Host "选项无效，已退出。" -ForegroundColor Red
            exit 1
        }
    }
}