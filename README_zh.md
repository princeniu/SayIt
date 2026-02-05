<p align="center">
  <img src="docs/assets/banner.png" width="400" alt="SayIt Banner">
</p>

# SayIt

<p align="center">
  <strong>基于本地 Whisper AI 驱动的 macOS 极简语音转文字工具。</strong>
</p>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg" alt="Swift"></a>
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/macOS-15+-blue.svg" alt="macOS"></a>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>简体中文</strong>
</p>

---

SayIt 是一款轻量级、注重隐私的 macOS 菜单栏应用，可瞬间将您的语音转换为文字。通过通过 `whisper.cpp` 本地运行 OpenAI 的 Whisper 模型，SayIt 确保您的数据永远不会离开您的机器，同时提供闪电般快速、高精度的转录。

## ✨ 核心特性

-   **全局热键**：在任何应用程序中通过单一组合键启动和停止录制（默认：`⌥ Space`）。
-   **智能音频路由（iPhone 联动）**：专为“合盖模式”（Clamshell Mode）深度优化。当您的 Mac 盖子合上使用外置显示器时，SayIt 会自动感应并无缝切换至您的 iPhone 麦克风（通过 Continuity 功能）。
-   **隐私至上**：100% 本地处理。无云端 API，无数据采集。
-   **无缝工作流**：捕获的文本会自动复制到您的剪贴板，随时可以粘贴。
-   **智能 HUD**：一个非侵入式的悬浮 HUD 实时显示转录进度。
-   **优雅 UI**：原生 macOS 外观感设计，配有精美的设置和状态弹出框。
-   **Whisper 集成**：支持多种 Whisper 模型（Small, Base, Tiny）以平衡性能与精度。

## 🚀 快速入门

### 前提条件

-   macOS 15.0 或更高版本。
-   Xcode 16.0 或更高版本。

### 安装步奏

1.  **克隆仓库**：
    ```bash
    git clone https://github.com/princeniu/SayIt.git
    cd SayIt
    ```

2.  **初始化子模块**：
    SayIt 使用 `whisper.cpp` 作为子模块。
    ```bash
    git submodule update --init --recursive
    ```

3.  **在 Xcode 中打开**：
    ```bash
    open SayIt/SayIt.xcodeproj
    ```

4.  **编译运行**：
    选择 **SayIt** Scheme 并按下 `⌘R`。

## 🛠 使用方法

1.  **授予权限**：首次启动时，SayIt 会请求麦克风和语音识别权限。
2.  **下载模型**：如果是首次使用 Whisper，请通过弹出框下载推荐的模型。
3.  **录音**：按下 `⌥ Space` 开始录音。菜单栏中会出现电量指示器。
4.  **停止**：再次按下 `⌥ Space`。转录会自动开始。
5.  **粘贴**：一旦 HUD 显示“Copied!”，您的文本就已在剪贴板中。只需在需要的地方按下 `⌘V`。

## 🏗 技术架构

SayIt 使用现代 Apple 技术构建：
-   **SwiftUI**：构建流程度、响应式的用户界面。
-   **Combine**：用于健壮的状态管理和异步数据流。
-   **whisper.cpp**：OpenAI Whisper 的高性能 C++ 实现。
-   **CoreAudio**：用于低延迟音频捕获。

## 🤝 参与贡献

欢迎任何形式的贡献！请随时提交 Pull Request。

1.  Fork 本项目。
2.  创建您的特性分支 (`git checkout -b feature/AmazingFeature`)。
3.  提交您的更改 (`git commit -m 'Add some AmazingFeature'`)。
4.  推送到分支 (`git push origin feature/AmazingFeature`)。
5.  开启一个 Pull Request。

## 📄 开源协议

根据 MIT 许可证进行分发。有关更多信息，请参见 `LICENSE`。

---

<p align="center">
  Made with ❤️ for the macOS Community.
</p>
