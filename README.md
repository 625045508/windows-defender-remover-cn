# ❌️ Defender Remover / Defender 卸载工具（简体中文版）

<a href="https://github.com/ionuttbara/windows-defender-remover">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="./site-res/new_darkmode.png">
        <img alt="Defender Remover" src="./site-res/new_lightmode.png">
    </picture>
</a>

> **关于本中文版**
> 这是 [ionuttbara/windows-defender-remover](https://github.com/ionuttbara/windows-defender-remover)（v13.1）的简体中文汉化分支，由 **DeepSeek Harness** 完成界面与提示文案汉化：
> 菜单、确认提示、备份/恢复输出、错误信息、批处理与 `verify.bat` 校验脚本全部中文；日志文件里的状态枚举（`FilesOnly`/`RemovedNotRestorable`/`AlreadyAbsent` 等）保持英文，方便对照上游排查。批处理统一 `chcp 65001` 切换到 UTF-8，避免中文乱码。
> **这个工具会真的删除系统安全组件，删除流程没有在汉化过程中被执行过**（只做了 PowerShell 语法解析、逐行核对，以及菜单/进程检测部分的中文运行验证）。请自行备份、建还原点后再用。
>
> **已编译版本：** `Defender-Remover-13.1-cn.exe`（1.4 MB，PS2EXE 打包，把 `script\` 下的脚本与注册表文件全部 base64 内嵌，运行时解包到 `%TEMP%\Script_Run_Payload` 再以管理员权限启动）。双击即可，未做代码签名，SmartScreen 可能提示未知发布者。
> 想自己编译：`Install-Module PS2EXE -Scope CurrentUser`，然后在 `script\` 目录运行 `powershell -ExecutionPolicy Bypass -File Build.ps1`。

## 下载（不用自己编译）

| 文件 | 说明 |
|---|---|
| [`Defender-Remover-13.1-cn.exe`](https://github.com/625045508/windows-defender-remover-cn/releases/download/v13.1-cn/Defender-Remover-13.1-cn.exe) | 单文件版，双击即用 |
| [`windows-defender-remover-cn-13.1.zip`](https://github.com/625045508/windows-defender-remover-cn/releases/download/v13.1-cn/windows-defender-remover-cn-13.1.zip) | 源码包（不含 exe） |

全部发布物见 [Releases](https://github.com/625045508/windows-defender-remover-cn/releases)。

## 项目模块

各子模块的详细说明见：

* **[💿 ISO 制作器](./ISO_Maker/README.md)** —— 生成一份已禁用 Defender 的自定义 Windows ISO。
* **[🛡️ Defender 移除引擎](./script/Remove_Defender/README.md)** —— 移除杀毒核心与服务。
* **[🖥️ 安全中心移除](./script/Remove_SecurityComp/README.md)** —— 移除 Windows 安全中心界面。

---

## ❓️ 这个程序做什么？

本程序会移除 / 禁用 Windows Defender，包括 Windows 安全中心应用、Windows 基于虚拟化的安全（VBS）、SmartScreen、Windows 安全服务、Web 威胁服务、文件虚拟化（UAC）、Microsoft Defender Application Guard、驱动阻止列表、系统缓解措施，以及 Windows 10 及更高版本「设置」里的 Windows Defender 页面。

## ❓️ 具体移除哪些组件？

### 移除安全组件

    本脚本会移除/禁用以下安全组件：
        - Windows 安全中心支持，包括 Windows 安全中心服务（wscsvc）、Windows 安全服务（SgrmBroker、Sgrm 驱动）——这些是运行 Windows 安全中心应用所必需的。
        - 虚拟化支持。
            - 虚拟机监控程序启动（这里修的是 VBS 被禁用的问题；如果你用 Hyper-V 和/或 WSL（Windows Subsystem for Linux）、WSA（Windows Subsystem for Android），它会自动重新启用）
            - LUA（禁用文件虚拟化与用户账户控制，所有程序都以管理员权限运行，顺带修复一些老程序的报错）
            - Exploit Guard（漏洞利用防护相关）
            - Windows Smart Control
            - 篡改防护（Windows 11 21H2 及更早版本）
        - SecHealthUI（Windows 安全中心 UWP 应用）
        - SmartScreen
        - Pluton 支持与 Pluton 服务支持
        - 系统缓解措施
          - 「服务缓解」（更多信息可在 admx.help 查到，属于策略项）
          - Spectre 与 Meltdown 缓解（在老款 Intel CPU 上能换来约 +30% 性能）
        - 「设置」应用里的「Windows 安全」页面。

### 移除杀毒组件

    本脚本会强制移除以下杀毒组件：
      - Windows Defender 病毒库更新列表（Defender 都没了，自然也要禁用病毒库更新）
      - Windows Defender SpyNet 遥测
      - 杀毒服务
      - Windows Defender 杀毒过滤驱动与 rootkit 扫描驱动
      - 杀毒扫描计划任务
      - Shell 关联（右键菜单）
      - 从 Windows 安全中心应用里隐藏「病毒和威胁防护」区块。

## 📃 使用方法

> [!NOTE]
> 建议在运行脚本前先创建一个系统还原点（尤其是你不清楚自己在做什么的时候）。

1. 从 [Releases](https://github.com/ionuttbara/windows-defender-remover/releases) 下载打包好的脚本
2. 以管理员身份运行 `.exe`
3. 按屏幕上的提示操作

或者

用 git：

```
git clone https://github.com/ionuttbara/windows-defender-remover.git
script/Script_Run.cmd
```


或者

下载完整源码：
1. 从 [Releases](https://github.com/ionuttbara/windows-defender-remover/releases) 下载源码。
2. 选最新版本的 **Source Code(.zip)** 下载。
3. 解压到某个文件夹，然后运行 `Script_Run.bat`。

![cli](https://github.com/drunkwinter/windows-defender-remover/assets/38593134/46007191-0a65-43c2-b451-a993ff90e00e)

遇到问题可以在 [issues](https://github.com/ionuttbara/windows-defender-remover/issues) 里反馈。

## 📃 脚本自动化

可以带参数直接移除 Defender。

#### 移除

```PowerShell
# 移除
Defender.Remover.exe /r <# 或 /R #>
```


## 禁用或移除 Windows Defender *Application Guard 策略*（进阶）

如果你打开某个程序（**极罕见**）时看到「The app can not run because Device Guard」或「Windows Defender Application Guard Blocked this app」，需要删除 4 个同名文件，它们位于不同位置。


- 在 EFI 分区

```PowerShell
Remove-Item -LiteralPath "$((Get-Partition | ? IsSystem).AccessPaths[0])Microsoft\\Boot\\WiSiPolicy.p7b"
```

- 在代码完整性目录

```PowerShell
Remove-Item -LiteralPath "$env:windir\\System32\\CodeIntegrity\\WiSiPolicy.p7b"
```

- 在 Windows 目录

```PowerShell
Remove-Item -LiteralPath "$env:windir\\Boot\\EFI\\wisipolicy.p7b"
```

- 在 WinSxS 目录

```PowerShell
Remove-Item -Path "$env:windir\\WinSxS" -Include *winsipolicy.p7b* -Recurse
```

## 制作已禁用 Defender 与安全服务的 ISO

你可以自己做一份关闭了 Windows Defender 与安全服务的 ISO。步骤很简单，下面就是完整的说明。
规则如下：
1. 挂载 ISO 并解压到某个位置。
2. 打开 **sources** 文件夹，新建 **$OEM$** 文件夹。（OOBE 阶段要跑 DefenderRemover 就靠它）。
3. 打开 **$OEM$** 文件夹，新建名为 **$$** 的文件夹。
4. 打开 **$$** 文件夹，新建名为 **Panther** 的文件夹。
5. 打开 **Panther** 文件夹。
   此时路径大致是
    **%解压后的 ISO 位置%\\sources\\$OEM$\\$$\\Panther\\**
6. 从仓库的 ISO_Maker 文件夹下载 `unnatended.xml`，放进 Panther 文件夹。
7. 保存为可引导 ISO。（目前脚本还不能自动完成这一步，下个版本会做）
    

## ❓ 常见问题

#### ⭕ 不下载脚本，怎么从电脑上移除 Windows 安全中心 / 安全中心应用？

把下面这段代码粘进一个 PowerShell 文件，然后**以管理员身份运行**。

```
$remove_appx = @("SecHealthUI"); $provisioned = get-appxprovisionedpackage -online; $appxpackage = get-appxpackage -allusers; $eol = @()
$store = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore'
$users = @('S-1-5-18'); if (test-path $store) {$users += $((dir $store -ea 0 |where {$_ -like '*S-1-5-21*'}).PSChildName)}
foreach ($choice in $remove_appx) { if ('' -eq $choice.Trim()) {continue}
  foreach ($appx in $($provisioned |where {$_.PackageName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageName = $appx.PackageName; $PackageFamilyName = ($appxpackage |where {$_.Name -eq $appx.DisplayName}).PackageFamilyName 
    ni "$store\\Deprovisioned\\$PackageFamilyName" -force >''; $PackageFamilyName  
    foreach ($sid in $users) {ni "$store\\EndOfLife\\$sid\\$PackageName" -force >''} ; $eol += $PackageName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxprovisionedpackage -packagename $PackageName -online -allusers >''
  }
  foreach ($appx in $($appxpackage |where {$_.PackageFullName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageFullName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageFullName = $appx.PackageFullName; 
    ni "$store\\Deprovisioned\\$appx.PackageFamilyName" -force >''; $PackageFullName
    foreach ($sid in $users) {ni "$store\\EndOfLife\\$sid\\$PackageFullName" -force >''} ; $eol += $PackageFullName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxpackage -package $PackageFullName -allusers >''
  }
}
```

#### ⭕ 为什么下载的 exe 会被报毒？

这是误报。

一些安全软件把这个程序当成病毒，是因为 `.exe` 的生成方式比较特殊。用 **git** 或源码 zip 就不太会被标记。
从 Defender 12.6.x 开始，某些版本会被判为病毒、某些不会（这是作者打包上的问题，不用为这个提 issue）。

#### ⭕ 为什么 Windows 更新之后补丁就不管用了？

Windows 更新里包含 ```Intelligence Update```，它会拦截某些操作并改写 Windows Defender / 安全策略。
如果脚本在你机器上没效果，先确认是否装了 Windows 安全智能更新。装了的话，关闭篡改防护，再重新运行脚本。

#### ⭕ 不下载 Release 里的 exe，怎么使用包移除器？

用 PowerRun 从 cmd 里运行对应的 `.bat` 文件（直接把文件拖到 PowerRun 的可执行文件上）。改动要重启后才生效。

#### ⭕ 移除脚本不起作用时，怎么关闭 VBS？

用这条命令关闭，然后重启。

```
bcdedit /set hypervisorlaunchtype off
```
之后你就用不了虚拟机了。  

#### ⭕  为什么 Windows 11 上 VBS 总是又自己打开？

脚本默认会关闭 VBS 来提升系统性能。让 VBS 重新启用的因素是 Windows 虚拟化。

使用 Windows 虚拟化的应用与功能：

- Windows Subsystem for **Android**/**Linux** —— Hyper-V 虚拟机
- <a href="https://apps.microsoft.com/detail/9n0tn65p5bf6?hl=en-US&gl=US" target="_blank">Microsoft Emulator</a>（Microsoft Store 里的 Windows 10X 模拟器）
- Visual Studio 里的 Android Studio 集成，或其它模拟器（Windows 10 22H2 且装有 2025 年 3 月更新或更新版本）

只要你打开上面提到的任意一个应用，VBS 就会在不需要你确认的情况下被启用——虚拟机引擎需要它。如果你根本不用虚拟机，可以到<a href="https://github.com/ionuttbara/windows-defender-remover/issues" target="_blank">这里</a>提 issue。
