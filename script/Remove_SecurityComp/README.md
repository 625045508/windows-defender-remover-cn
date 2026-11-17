# 移除安全中心组件（界面与中心服务）

本模块负责移除 Windows 安全中心的外观与系统集成部分。

## 会移除什么？

* **Windows 安全中心应用：** 开始菜单里那个 UWP 应用（SecHealthUI）。
* **Windows 安全中心服务（wscsvc）：** 监控安全状态的那个服务。
* **「设置」页面：** 从 Windows「设置」应用里去掉「Windows 安全」区块。
* **系统托盘图标：** 任务栏上的盾牌图标。

## 用 PowerShell 手动移除

如果你不想用整套移除流程、只想干掉安全中心应用，可以运行下面这段 PowerShell，
保存成 ps1，再用 PowerRun 运行。

```powershell
$remove_appx = @("SecHealthUI"); $provisioned = get-appxprovisionedpackage -online; $appxpackage = get-appxpackage -allusers; $eol = @()
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$users = @('S-1-5-18'); if (test-path $store) {$users += $((dir $store -ea 0 |where {$_ -like '*S-1-5-21*'}).PSChildName)}
foreach ($choice in $remove_appx) { if ('' -eq $choice.Trim()) {continue}
  foreach ($appx in $($provisioned |where {$_.PackageName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageName = $appx.PackageName; $PackageFamilyName = ($appxpackage |where {$_.Name -eq $appx.DisplayName}).PackageFamilyName 
    ni "$store\Deprovisioned\$PackageFamilyName" -force >''; $PackageFamilyName  
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageName" -force >''} ; $eol += $PackageName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxprovisionedpackage -packagename $PackageName -online -allusers >''
  }
  foreach ($appx in $($appxpackage |where {$_.PackageFullName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageFullName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageFullName = $appx.PackageFullName; 
    ni "$store\Deprovisioned\$appx.PackageFamilyName" -force >''; $PackageFullName
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageFullName" -force >''} ; $eol += $PackageFullName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxpackage -package $PackageFullName -allusers >''
  }
}
)

```

注意！这个 .ps1 文件必须用 PowerRun 运行。

命令参数是


```cmd
Powerrun powershell.exe -noprofile -executionpolicy bypass -file "RemoveSecHealthApp.ps1"
```
