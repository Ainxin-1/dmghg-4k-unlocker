# 🎬 DMGHG 4K 画质解锁 / 4K Quality Unlocker

解除 **动漫共和国 (dmghg)** 的 4K 画质 VIP 限制，免费观看所有清晰度。

Removes the 4K quality VIP restriction in **dmghg** (动漫共和国) — enjoy all resolutions for free.

---

## 使用方法 / How to Use

### 方式一：一键解锁（推荐）

1. **下载** `dmghg-4k-unlocker.bat`
2. 将 `dmghg-4k-unlocker.bat` **放到 dmghg 安装目录**需要和 `dmghg.exe` 在同一文件夹
3. **启动"动漫共和国"自动加载此脚本**

### 方式二：保留修改（更新后自动恢复）

1. 按方式一解锁
2. 再将 `setup-autorun.bat` 也放入 dmghg 目录，**以管理员身份运行**
3. 以后每次 dmghg 自动更新后，下次开机登录时会自动重新解锁

---

## 原理 / How It Works

dmghg 的 4K 画质被标记为 `vip_type: 1`，播放前会检查 `Users.isVip()`：

- 非 VIP 用户 → 过滤掉 4K 画质
- VIP 用户 → 正常显示

本工具修改 `app.asar` 中的 `Users.isVip` 方法，使其**始终返回 true**，从而绕过检测。

> 本质上是修改 Electron 应用的 ASAR 包，类似游戏打 Mod。

---

## 文件说明 / Files

| 文件 | 说明 |
|------|------|
| `patch-4k.bat` | 主程序 — 一键解锁 4K |
| `setup-autorun.bat` | 可选 — 设置开机自动修补（应对自动更新） |

---

## 注意事项 / Notes

- ⚠ 首次使用请**以管理员身份运行**（需要写入 `app.asar`）
- dmghg 自动更新后会覆盖 `app.asar`，需要重新执行 `patch-4k.bat`
- 建议配合 `setup-autorun.bat` 使用，开机自动检测并修补
- 本工具仅用于学习研究，请支持正版
