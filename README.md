﻿# ⚡ PulseLite · 跨品牌外设电量与回报率调度器

<p align="center">
  <img src="app.png" width="108" height="108" alt="PulseLite Logo" />
</p>

<p align="center">
  <b>进游戏自动切换回报率用的</b><br>
  <i>原生轻量 Windows 任务栏工具</i>
</p>

<p align="center">
  <a href="https://github.com/alex450/pulselite"><img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=flat-square&logo=windows" alt="Platform" /></a>
  <a href="https://github.com/alex450/pulselite"><img src="https://img.shields.io/badge/.NET%20Framework-4.0%20(Pure%20Native)-512BD4?style=flat-square&logo=dotnet" alt=".NET Framework" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL%20v3.0-blue.svg?style=flat-square" alt="License: GPL v3" /></a>
  <a href="https://github.com/Ferris-echo/FerrisPulse"><img src="https://img.shields.io/badge/Upstream-FerrisPulse%20v2.2.0-00ff88?style=flat-square" alt="Upstream" /></a>
</p>

---

## 📖 这是什么

**PulseLite** 是 [FerrisPulse · 灵脉](https://github.com/Ferris-echo/FerrisPulse) 的精简分支（基于上游 v2.2.0，遵循 GPLv3）。

它只保留"看电量 + 进游戏自动提回报率"这条主线，把打扰性的浮窗、切换提示音与样式选择全部砍掉：**没有 OSD 浮窗、没有切换提示音**，安安静静待在托盘里（低电量气泡提醒仍保留，可在设置里关掉）。

### ✅ 保留的能力

* 🔋 **跨品牌电量读取**：雷蛇、罗技（Lightspeed / 优联）、NuPhy、ATK / VGN / VXE / 迈从 / 狼蛛，以及常见蓝牙耳机。
* 🆕 **v2.2.0 新硬件**：赛睿 Nova5、HyperX、索尼 INZONE Buds、Apple/Beats、飞智 APEX 6、迈从 A5 V2 Ultra / G87 V2、雷蛇 DA V2X / 黑鲨 V2 Pro 等
* 🎮 **全屏游戏自动切换回报率**：常规回报率与电竞回报率双档，命中守护列表的游戏自动切到 4000Hz / 8000Hz，离开游戏回落节能档。
* 🔒 **「游戏退出前保持电竞回报率」**：勾选后，切出焦点（回桌面、开浏览器）不再回落，只有游戏进程真正退出才恢复——避免反复抖动。
* 🎯 **雷蛇 DPI 档位**：板载档位读写、自定义档位、硬件按键改 DPI 后界面自动同步。
* ⌨️ **键盘控制**：NuPhy 休眠超时 / WinLock / 背光，以及其他品牌的 WinLock 锁定。
* 🖱️ **外设管理**：多设备标签页、优先级拖拽排序、自定义昵称与分类、无感休眠与唤醒。

### ❌ 相对上游移除的部分

| 移除项 | 说明 |
|---|---|
| 切换提醒 | OSD 浮窗、Windows 系统通知、柔和提示音全部移除，切换回报率时不再有任何弹窗与声音 |
| 托盘图标样式选择 | 固定为「醒目数字能量表」 |
| 自动刷新频率设置 | 固定 **1 分钟** |
| DPI 浮窗（OSD） | 整个 DPI 悬浮提示窗及其样式选择已删除；硬件按键改 DPI 仍会同步到界面 |

---

## 🏛️ 架构

```
pulselite/
├── src/
│   ├── Core/         # 单例守护、Win32 消息循环、注册表自启动、原子热更新
│   ├── Hardware/     # 底层 HID 通信与私有协议解构 (Razer 90B / Logitech HID++ / CompX)
│   ├── Models/       # 外设状态模型与配置持久化契约
│   ├── Services/     # 前台游戏焦点检测、回报率调度、更新与音效合成
│   └── UI/           # Win11 Mica 窗体、GDI+ 自绘控件、托盘与主界面
├── build.bat             # 原生构建，产物 PulseLite.exe
└── buildtodesktop.bat    # 同上，但输出到桌面（可用参数指定目录）
```

### 1. 跨品牌硬件私有 HID 协议直连

* **雷蛇 (Razer)**：解构专有 90 字节双向 Report 协议，直连 2.4G 接收器与有线通道，免开雷云即可读电量、切回报率。
* **罗技 (Logitech)**：原生 **HID++ 1.0 / 2.0+** 协议引擎，握手 Lightspeed 与优联接收器，读取固件全称与精准百分比。
* **NuPhy (努斐)**：休眠超时、WinLock、RGB 背光与无级亮度。
* **国产电竞矩阵 (CompX 方案)**：ATK、VGN、VXE、迈从 (MCHOSE)、狼蛛 (AULA) 等 8K 无线鼠标。

### 2. 回报率调度怎么工作

1. **每秒轮询一次焦点窗口**：`GetForegroundWindow` → `GetWindowThreadProcessId` → 进程名与守护列表比对（不需要全屏，窗口化/无边框也能命中）。
2. **兜底模式**（可选）：未命中列表时，用 `SHQueryUserNotificationState` 的独占全屏状态 + 窗口矩形覆盖整屏做判断，并排除资源管理器、浏览器与播放器。
3. **消抖**：连续 2 个周期（约 2 秒）才真正切换，避免 Alt+Tab 抖动误触发。
4. **保持选项**：勾选「游戏退出前保持电竞回报率」后，只要触发本次切换的游戏进程仍在运行，焦点切走也不回落。

### 3. 极速纯原生编译

* 严格 **C# 5.0 / .NET Framework 4.0**，零第三方 DLL、零 NuGet 依赖。
* Windows 10 / 11 自带运行环境，单文件即跑。

---

## 🛡️ 反作弊与安全性

> **问：在《无畏契约》《CS2》《Apex 英雄》等竞技游戏里使用会被封号吗？**

**答：不会。**

1. **纯标准 Windows API**：只用 `user32.dll` 查询"当前哪个窗口在最前台"，和 OBS / Discord 判断你是否在玩游戏是同一类调用。
2. **纯标准 HID 通信**：切换回报率时发送的是鼠标固件公开支持的标准 HID 特征包，等同于你在官方驱动里点一下"切换回报率"。
3. **零敏感行为**：不调用 `OpenProcess(PROCESS_VM_READ/WRITE)` 读写游戏内存，不挂 API Hook，不注入 DLL。

---

## 🛠️ 本地编译

不需要 Visual Studio，用系统自带的 .NET Framework 编译器即可：

```cmd
:: 1. 克隆仓库
git clone https://github.com/alex450/pulselite.git
cd pulselite

:: 2A. 编译到仓库目录，产物 PulseLite.exe
build.bat

:: 2B. 或编译到桌面（避免把 exe 留在代码目录；可传参指定目录）
buildtodesktop.bat
buildtodesktop.bat D:\out
```

产物为单文件 **`PulseLite.exe`**，直接双击运行，无需安装。

> 注意：不要从 DSH / 沙箱工作区目录里运行编译产物——那里的文件带 Low 完整性标签，会导致读不到运行中的应用列表。用 `buildtodesktop.bat` 输出到桌面即可避开。

---

## 🔁 与上游同步

本仓库保留了上游远端，方便继续跟进：

```cmd
git fetch upstream
git merge upstream/main
```

上游相关提交只改动业务代码；合并后请确认 `SetGameRateControlsVisibility` 里仍然包含 PulseLite 新增的控件、以及 `build.bat` 的输出名未被覆盖回 `FerrisPulse.exe`。

---

## 📄 许可证与致谢

* 本项目遵循 **[GNU General Public License v3.0 (GPLv3)](LICENSE)**，与上游一致。
* 原始项目：[**FerrisPulse · 灵脉**](https://github.com/Ferris-echo/FerrisPulse)，作者 **Ferris-echo**。PulseLite 的全部硬件协议与界面基座均来自该项目，在此致谢。
* 二次分发时请同样保留 GPLv3 与上述署名。

<p align="center">
  <b>如果 PulseLite 好用，也请顺手给上游 FerrisPulse 点一颗 ⭐️</b>
</p>