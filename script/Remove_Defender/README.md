# 移除 Defender 核心（引擎与服务）

本目录存放专门用来瓦解 Windows Defender 后台的注册表文件与脚本。

## 会移除什么？

运行本目录的脚本会强制移除或禁用：

* **杀毒服务：** 拦截文件执行的主引擎。
* **Windows Defender 驱动：** 包括 rootkit 扫描器与文件系统过滤驱动。
* **SmartScreen：** 拦截「未识别」应用的过滤器。
* **SpyNet 遥测：** 阻止数据回传微软。
* **计划任务：** 关闭自动扫描与维护任务。
* **右键菜单：** 从右键菜单里去掉「使用 Windows Defender 扫描」。

## 用法

这些文件通常由 `Script_Run.bat` 主脚本自动调用，也可以单独拿来排错或按需使用。

* **注册表项（.reg）：** 双击即可合并进注册表。
* **关闭缓解措施：** 用 `Disable Mitigation.reg` 关闭漏洞利用防护相关功能。

> **说明：** 移除这些内容之后，「Windows 安全中心」应用通常还在，只是里面的杀毒防护会失效/被禁用。如果连界面也要去掉，见 [Remove_SecurityComp](../Remove_SecurityComp/README.md) 模块。
