DEFENDER REMOVER 13.1 - 备份 / 恢复
====================================

备份位置：
  C:\ProgramData\Gallery Inc\Defender Remover\schemas

每次执行删除都会新建一个带时间戳的方案（schema）目录，里面包含：
  Manifest.json       操作日志与恢复状态
  Files\              已成功删除的文件/文件夹备份
  Registry\Keys\     被修改/删除的注册表项的 .reg 导出
  Registry\Values\   因导入而被改动的注册表值的 .reg 快照
  Staging\            操作前的临时快照

删除器会先备份文件/文件夹内容再尝试删除。如果备份无法复制并校验通过，
该项就不会被删除。注册表导入前同样会先做快照；只有导入之后确认过的改动
才会留作已完成的恢复条目。每个破坏性步骤之前都会先写一份小的变更日志，
这样即使操作被中断，重启之后也能安全回滚。
机器级注册表配置单元（.reg）通过提权的 PowerRun 路径处理；HKCU/HKCR 部分
在交互用户自己的提权进程里导入，以免被重定向到 SYSTEM 配置文件。

使用「开始菜单 > 程序 > Defender Remover > 恢复 Defender」。恢复启动器会
申请管理员权限，把保存的文件与注册表数据写回，并标记已完成的方案，避免重复
恢复。恢复之后建议重启。恢复完成后备份方案仍会保留。

重要 - WINDOWS 安全中心应用
如果你选择并确认移除 Windows 安全中心应用（SecHealthUI），它的 AppX 包
**不会**被备份。恢复 Defender 不会把它装回来，方案与恢复界面里也会显示这一
限制。不要把这个恢复功能当成恢复 Windows 安全中心应用包的手段。

POWERSHELL 执行策略
启动器只在当前 PowerShell 进程内使用 `-NoProfile -ExecutionPolicy Bypass`，
不会修改机器级或用户级的执行策略。组策略设置（MachinePolicy / UserPolicy）
可能会覆盖这个进程级设置。在全新安装的 Windows 上，请用 Build.cmd 以同样的
进程级绕过方式启动构建器。

方案里包含系统文件与注册表数据。除非你确定要丢弃对应的还原点，否则不要编辑
或删除它们。

版本 13.1 - 进程检查
主菜单会对 MsMpEng、NisSrv 与 SecurityHealthService 做一次只读检查。检测到的
进程名与 PID 会写进备份的 Manifest.json。不会终止、挂起或修改任何 Defender
进程。菜单输入使用 .NET Console I/O，以避免某些 PS2EXE 控制台构建里
Read-Host 出现的提示顺序问题。
