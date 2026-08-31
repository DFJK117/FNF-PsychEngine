# 🎵 Doubao Engine（豆包引擎）

> 基于 **Psych Engine 1.0.4** 深度改造的 Friday Night Funkin' 游戏引擎，主打多键位、双人同键盘与完整中文体验。

![GitHub Workflow Status](https://github.com/DFJK117/FNF-PsychEngine/actions/workflows/main.yml/badge.svg)
![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Language](https://img.shields.io/badge/language-Haxe%20%2F%20Lua-orange)
![License](https://img.shields.io/badge/license-Apache--2.0-green)

---

## 📖 引擎简介

Doubao Engine（豆包引擎）在开源引擎 [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) 基础上二次开发，新增了**多 K 键位**、**双人同键盘对战**与**简体中文本地化**，并保留完整的 Psych Lua / HScript 模组 API。

---

## ✨ 核心特性

| 特性 | 说明 | 状态 |
| :--- | :--- | :---: |
| 🎮 双人键盘模式 | P1 操控左侧对手（Dad），P2 操控右侧 BF，独立判定线 | ✅ 已支持 |
| 🎹 多 K 键位 | 4K / 5K / 6K / 7K / 8K / 9K，箭头自动缩小不拥挤 | ✅ 已支持 |
| 🇨🇳 简体中文 | 界面、选项、提示完整中文化，默认中文 | ✅ 已支持 |
| ⚡ 性能优化 | 箭头随键位缩放降低填充、击中即时销毁回收 | ✅ 已支持 |
| 📜 Lua 脚本 | 完整保留 Psych Lua API，模组兼容 | ✅ 已支持 |
| 🎬 视频过场 | 基于 hxvlc 的视频播放 | ✅ 已支持 |
| 🔄 谱面自动转键 | 4K↔多K 纯算法重映射、少K智能避让叠键 | 📋 规划中 |
| 🎨 P1 独立配色 | 第二位玩家自定义箭头颜色 | 📋 规划中 |

> ✅ 已可用　🚧 开发中　📋 规划中

---

## 🎮 键位说明

### 单人 4K（与原版一致）

`W A S D` 与 `方向键` 均可，支持在选项里自行改键。

### 多 K / 双人模式（固定物理键位）

| 轨道（从左到右） | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| :--- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| **P1 对手（左）** | A | S | W | D | F | G | H | J | K |
| **P2 BF（右）** | ← | ↓ | ↑ | → | Z | X | C | V | B |

- **P1 = 左侧对手 Dad**，**P2 = 右侧 BF**，请勿搞反。
- 键位数为 4K 时，前 4 个键正好对应经典布局。
- 双人模式下 P1 可在选项里单独开启**下滚**。

### 如何开启

进入 `选项 → Gameplay Settings（玩法设置）`：

- **Two Player Mode**：双人键盘开关
- **Lane Count (4K-9K)**：每侧轨道数量，左右键调整，开局生效
- **P1 Downscroll**：双人模式下 P1（对手侧）独立下滚

---

## 📥 下载

前往 [**Actions 构建页**](https://github.com/DFJK117/FNF-PsychEngine/actions) 下载最新自动构建的 Windows 版本：

1. 点击最新一次显示 **Success**（绿色✓）的构建
2. 下拉到页面底部 **Artifacts**
3. 下载 `windowsBuild` 压缩包
4. 解压后运行 `.exe` 即可

> ⚠️ 需要登录 GitHub 账号才能下载 Actions 产物。本引擎仅提供 Windows 构建。

---

## 🔨 自行编译

### Windows 环境要求

- [Haxe 4.3.4](https://haxe.org/download/)
- 依次执行 `setup/windows.bat` 安装依赖库

### 编译命令

```bash
haxelib run lime build windows
```

### 依赖库版本（精确对应）

| 库 | 版本 |
| :--- | :--- |
| lime | 8.1.2 |
| openfl | 9.3.3 |
| flixel | 5.6.1 |
| flixel-addons | 3.2.2 |
| hscript-iris | 1.1.3 |
| tjson | 1.4.0 |
| hxdiscord_rpc | 1.2.4 |
| hxvlc | 2.0.1 |

---

## 🧩 实现要点（开发者）

- `source/backend/DoubaoConfig.hx`：集中管理键位数、双人开关、轨道间距/箭头缩放、P1/P2 物理键位。
- 谱面加载（`Song.hx`）与音符生成（`PlayState.hx`）的轨道归属由固定 4 改为动态键位数。
- 颜色 / 动画 / 贴图帧索引统一按 `% 4` 循环，多 K 轨道复用四色箭头。
- 双人模式下双方音符均为手动判定，靠 `Note.isOpponent` 区分归属与判定线。
- 中文走 `assets/translations/shared/data/zh-CN.lang`，Windows 下字体自动回退到微软雅黑。

---

## 🙏 致谢

- [ShadowMario / Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) — 原始引擎
- [Leather128 / Leather Engine](https://github.com/Leather128/LeatherEngine) — 多键位参考
- [HaxeFlixel](https://haxeflixel.com/) — 底层游戏框架
- 所有 FNF 开源社区的贡献者

---

## 📜 许可证

本项目遵循 [Apache License 2.0](LICENSE) 开源协议。

Friday Night Funkin' 原版由 [The Funkin' Crew](https://ninja-muffin24.itch.io/funkin) 制作。
