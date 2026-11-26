# 贡献指南 (Contributing Guide)

欢迎来到《**清风计划 · 清风系统**》（*Breeze System*）开源仓库！无论是修复一个小 Bug、优化 SwiftUI 界面视觉，还是提出新的灵感创意，都非常欢迎你的参与。

Welcome to **Breeze System**! Whether it's fixing a bug, refining the SwiftUI interface, or sharing new ideas inspired by *Project Breeze*, your contributions are warmly welcomed.

---

## 💡 你可以如何参与 (How to Contribute)

1. **反馈问题 (Report Bugs)**
   * 如果你在特定 macOS 版本上遇到闪退、图标显示异常或误识别系统进程的情况，请在 **Issues** 中新建问题，并尽量附上你的 macOS 版本号与复现步骤。
2. **提出新功能建议 (Suggest Features)**
   * 如果你有让系统更清爽、更智能的好点子（例如开机自启配置、CPU/内存占用阈值提醒等），欢迎随时在 **Issues** 中发起讨论。
3. **提交代码改进 (Pull Requests)**
   * Fork 本仓库并创建你的功能分支（例如 `git checkout -b feature/whitelist-manager`）。
   * 保持代码简洁、零冗余第三方依赖（优先使用 macOS 原生 `SwiftUI`、`AppKit`、`IOKit` 或标准 C/C++）。
   * 提交前请在本地确保编译通过且不会误伤 macOS 系统核心进程。

---

## 🛠️ 本地开发环境要求 (Development Setup)

* **操作系统**：macOS 12.0 (Monterey) 或更高版本
* **编译工具**：Xcode Command Line Tools（内置 `swiftc` 与 `clang++`）

### 快速本地编译测试
```bash
# 编译 SwiftUI 图形界面版
swiftc BreezeApp.swift -o BreezeSystem
```

---

## 📏 语义化版本规范 (Versioning)

本项目遵循 `主版本.次版本.修订号`（Semantic Versioning）规范：
* **Patch (`v2.0.1`)**：Bug 修复、白名单规则微调、文档更新。
* **Minor (`v2.1.0`)**：新增实用功能（如后台进程扫描、界面列表优化）。
* **Major (`v3.0.0`)**：核心架构或交互模式的重大重构。

再次感谢你为《清风计划》注入的每一份灵感与代码！🍃
