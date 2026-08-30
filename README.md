# 🎵 Doubao Engine（豆包引擎）

> 基于 **Psych Engine** 深度优化的 Friday Night Funkin' 游戏引擎，专注性能、多键位与双人玩法。

![GitHub Workflow Status](https://github.com/DFJK117/FNF-PsychEngine/actions/workflows/main.yml/badge.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Android-blue)
![Language](https://img.shields.io/badge/language-Haxe%20%2F%20Lua-orange)
![License](https://img.shields.io/badge/license-Apache--2.0-green)

---

## 📖 引擎简介

Doubao Engine（豆包引擎）是在开源引擎 [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) 基础上进行二次开发的 FNF 引擎。原始引擎最初用于 [Mind Games Mod](https://gamebanana.com/mods/301107)，旨在修复原版的大量问题，同时保持休闲游玩的体验，并为新手开发者提供更友好的模组编写方式。

本引擎在此基础上进一步追求**极致性能**、**多键位支持**与**双人同键盘对战**，并提供完整的中文本地化。

---

## ✨ 核心特性

| 特性 | 说明 | 状态 |
| :--- | :--- | :---: |
| 🎮 双人键盘模式 | P1 操控对手（Dad），P2 操控 BF，各自独立按键与配色 | 🚧 开发中 |
| 🎹 多 K 键位支持 | 4K / 5K / 6K / 7K / 9K 箭头，参考 Leather Engine | 🚧 开发中 |
| 🔄 键位算法转换 | 4K↔多K 纯算法转换，多K转少K智能避让叠键 | 🚧 开发中 |
| 🇨🇳 中文本地化 | 界面、选项、贴图全面中文化 | 🚧 开发中 |
| ⚡ 性能优化 | 对象池、渲染优化、内存回收模拟 | 🚧 开发中 |
| 📜 Lua 脚本 | 完整保留 Psych Lua API，模组兼容 | ✅ 已支持 |
| 🎬 视频过场 | 基于 hxvlc 的视频播放 | ✅ 已支持 |
| 🎨 HScript | 热重载脚本支持 | ✅ 已支持 |

> ✅ 已可用　🚧 开发中　📋 规划中

---

## 📥 下载

前往 [**Actions 构建页**](https://github.com/DFJK117/FNF-PsychEngine/actions) 下载最新自动构建的 Windows 版本：

1. 点击最新一次显示 **Success**（绿色✓）的构建
2. 下拉到页面底部 **Artifacts**
3. 下载 `windowsBuild` 压缩包
4. 解压后运行 `.exe` 即可

> ⚠️ 需要登录 GitHub 账号才能下载 Actions 产物。

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

更多细节见 [BUILDING.md](docs/BUILDING.md)。

---

## 🎮 双人模式设计（规划）

- **玩家 1（左侧）**：操控对手 Dad，默认按键 `W A S D`
- **玩家 2（右侧）**：操控 BF，默认按键 `方向键`
- 开启双人模式后可选择是否关闭箭头居中
- 每位玩家可独立调整：
  - 按键颜色
  - 上滚 / 下滚方向
  - 判定偏移

---

## 🎹 多 K 键位设计（规划）

- 键位增多时箭头**自动等比缩小**，避免拥挤
- 4K → 多K：算法自动分配箭头轨道
- 多K → 4K：智能合并，尽量避免叠键
- 参考 [Leather Engine](https://github.com/Leather128/LeatherEngine) 的多键箭头样式

---

## 📁 目录结构

```
FNF-PsychEngine/
├── source/            # 引擎源代码（Haxe）
│   ├── states/        # 游戏状态
│   ├── objects/       # 箭头、角色等对象
│   ├── psychlua/      # Lua 脚本引擎
│   └── options/       # 选项菜单
├── assets/            # 游戏资源
├── mods/              # 模组目录
├── setup/             # 环境安装脚本
└── Project.xml        # 编译配置
```

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
