# 安全策略与使用须知 (Security Policy)

感谢您关注并使用《**清风系统**》（*Breeze System*）。由于本工具涉及系统级进程扫描与强制终止操作，请在使用及反馈安全问题前仔细阅读以下声明。

Thank you for using **Breeze System**. Because this tool involves system-level process scanning and termination, please read the following security guidelines carefully before use.

---

## 🛡️ 支持的版本 (Supported Versions)

目前我们仅对最新的正式版本提供安全更新与维护支持：

| 版本 (Version) | 支持状态 (Supported) | 说明 (Notes) |
| :--- | :--- | :--- |
| **v2.x** (SwiftUI 菜单栏图形版) | ✅ 支持 (Yes) | 推荐日常使用，内置基础系统保护与白名单持久化 |
| **v1.x** (C++ 命令行版) | ⚠️ 仅作归档 (Archived) | 仅供学习与参考，请自行配置初始白名单后再运行 |

---

## ⚠️ 进程清理与白名单安全须知 (Process & Whitelist Safety)

1. **强制终止风险 (`SIGKILL`)**：
   本程序在执行“清理”操作时，会直接向目标进程发送不可捕获的强制终止信号（`SIGKILL` / `forceTerminate`）。目标软件中**未保存的文档、代码或数据将会立即丢失**，操作前请务必核对进程名称。
2. **保护关键系统与开发进程**：
   * 切勿强行结束任何名称陌生、或您无法确认用途的底层系统守护进程，否则可能导致桌面卡死、窗口管理器崩溃甚至系统重启。
   * 建议在首次使用时，将常用的终端（如 `Terminal`、`iTerm2`）、代码编辑器（如 `VS Code`、`Xcode`）及主力办公软件点击**“放行”**加入白名单。
3. **本地存储安全**：
   图形版的白名单配置仅保存在当前用户的系统偏好设置（`UserDefaults`）中，不会上传至任何远程服务器。

---

## 🐛 报告安全漏洞 (Reporting a Vulnerability)

如果您在使用过程中发现以下问题，请及时向我们反馈：
* 系统关键路径（如 `/System/`、`/usr/`）过滤规则被绕过，导致误报系统核心进程；
* 权限提升或本地配置文件读写存在安全隐患。

**反馈方式**：
* 请直接在 GitHub 仓库的 **Issues** 页面提交详细描述（请附上您的 macOS 版本号、触发问题的进程路径截图或日志，切勿包含个人隐私密码）。
* 我们会在收到反馈后尽快核查并在下一个修订版本中修复。
