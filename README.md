# DMGHG 4K Unlocker

解除动漫共和国 4K VIP 限制，纯 PowerShell 实现，无需 Node.js。

## 快速开始

1. 将 `dmghg-4k-unlocker.bat` 放到 `dmghg.exe` 所在目录
2. 双击运行（自动请求管理员权限）
3. 修补完成后动漫共和国自动启动

## 功能

| 功能 | 说明 |
|------|------|
| 4K 解锁 | 解除 VIP 限制，免费观看所有 4K 画质 |
| 视频缓存 | 观看记录正常保存，不会因 403 报错 |
| 弹窗屏蔽 | 屏蔽聚点 APP 付费弹窗 |
| 桌面快捷方式 | 自动将"动漫共和国"快捷方式指向本脚本 |
| 开机自检 | dmghg 更新后自动重新修补 |


## 恢复原始状态

以管理员身份运行：

```
dmghg-4k-unlocker.bat --restore
```

## 技术原理

脚本内嵌纯 PowerShell 实现的 asar 解包/打包引擎，不依赖 Node.js、npx 或任何第三方工具。
