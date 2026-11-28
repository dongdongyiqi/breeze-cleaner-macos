# 清风系统 (Breeze System for macOS)

一款轻量级的 macOS 后台进程巡检与交互式清理守护工具，使用原生 C++ 编写，无需任何第三方依赖，帮助你保持系统清爽、拦截多余后台驻留软件。

A lightweight, dependency-free macOS background process monitor and interactive cleaner written in native C++.

---

## ✨ 核心特性 (Features)

* **全雷达进程扫描 (Full Process Scanning)**：基于 macOS 原生 `libproc` API 实时遍历系统进程，精准识别 `/Applications/`、`/Library/Frameworks/` 及用户目录下的第三方应用。
* **系统级安全保护 (System-Level Protection)**：自动跳过 `/System/`、`/usr/` 核心系统路径及 `.appex` 系统扩展，防止误杀关键系统服务。
* **原生弹窗交互 (Native macOS Dialog)**：通过 `osascript` 调用原生系统提示框（15 秒超时自动跳过），支持一键**彻底清理 (`SIGKILL`)** 或 **放行并记住**。
* **双层白名单机制 (Dual Whitelist)**：支持整包路径放行（`ALLOWED_APPS`）与动态进程名白名单（`WHITELIST`）。

---

## 🚀 快速开始 (Quick Start)

### 1. 环境要求 (Prerequisites)
* macOS 操作系统
* Xcode Command Line Tools (`clang++`)

### 2. 编译代码 (Build)
在终端中进入项目目录，执行以下命令进行编译：

```bash
clang++ -std=c++17 -O2 main.cpp -o breeze
```
*(注：如果你本地的文件名为 `清风系统1.cpp`，请将命令中的 `main.cpp` 替换为对应的文件名)*

### 3. 运行程序 (Run)
```bash
./breeze
```
*(提示：如需结束未在当前用户权限下的进程，可使用 `sudo ./breeze` 运行)*

---

## ⚙️ 自定义配置 (Configuration)

在源码顶部可以直接配置你的默认信任软件：

```cpp
// 1. 整包放行列表（包含主程序及其所有 Helper/插件/子进程）
const std::vector<std::string> ALLOWED_APPS = {
    "Safari.app",
    "Visual Studio Code.app",
    "Terminal.app"
};

// 2. 初始动态白名单（进程名）
std::unordered_set<std::string> WHITELIST = {
    "breeze"
};
```

---

## ⚠️ 免责声明 (Disclaimer)

* 本工具在执行清理时会直接向目标进程发送 `SIGKILL` 强制终止信号，未保存的工作数据可能会丢失，请在弹窗确认时仔细核对进程列表。
* 建议在首次运行前，将常用的终端工具（如 `Terminal`、`iTerm2`）及代码编辑器加入白名单。

## 📄 开源协议 (License)

本项目基于 [MIT License](LICENSE) 开源。

[![Release](https://img.shields.io/github/v/release/dongdongyiqi/breeze-cleaner-macos?color=brightgreen&label=最新版本)](https://github.com/dongdongyiqi/breeze-cleaner-macos/releases)
[![Platform](https://img.shields.io/badge/平台-macOS-blue)](#)
[![Language](https://img.shields.io/badge/语言-C%2B%2B-orange)](#)
[![License](https://img.shields.io/badge/协议-MIT-purple)](#)
