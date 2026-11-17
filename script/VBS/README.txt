Defender Remover —— 开始菜单里的 VBS 操作

Defender Remover 以管理员权限启动后，会把两个 VBS 批处理脚本及其启动器复制到：
  %ProgramData%\Gallery Inc\Defender Remover\VBS

它会在所有用户的开始菜单下创建快捷方式：
  开始菜单 > 程序 > Defender Remover
    - 启用 VBS
    - 关闭 VBS

这些快捷方式通过会弹 UAC 的启动器运行随附的批处理文件。
两个操作都会修改启动配置，并在你确认之后重启 Windows。
开机时可能需要固件层面的确认。如果启用了 BitLocker，请先暂停保护再修改 EFI 启动设置，
并确保手里有恢复密钥。微软说明过：改动 BCD 可能触发 BitLocker 恢复。

Credential Guard 说明：启用 UEFI 锁定时 LsaCfgFlags 会被设为 1；关闭时系统与策略两处
注册表位置的 LsaCfgFlags 都会被设为 0。按微软文档，仅删除 LsaCfgFlags 可能并不能关闭
Credential Guard，走注册表关闭路径必须把它设为 0。
