<p align="center">
  <img src="docs/assets/banner.png" width="400" alt="SayIt Banner">
</p>

# SayIt

<p align="center">
  <strong>Effortless Voice-to-Text for macOS, Powered by On-Device Whisper AI.</strong>
</p>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg" alt="Swift"></a>
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/macOS-15+-blue.svg" alt="macOS"></a>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  <strong>English</strong> | <a href="README_zh.md">简体中文</a>
</p>

---

SayIt is a lightweight, privacy-focused macOS menu bar application that transcribes your voice into text instantly. By leveraging OpenAI's Whisper model running locally via `whisper.cpp`, SayIt ensures your data never leaves your machine while providing lightning-fast, high-accuracy transcriptions.

## ✨ Key Features

-   **Global Hotkey**: Start and stop recording from any application with a single key combination (Default: `⌥ Space`).
-   **Privacy First**: 100% on-device processing. No cloud APIs, no data collection.
-   **Seamless Workflow**: Captured text is automatically copied to your clipboard, ready to paste.
-   **Smart HUD**: A non-intrusive floating HUD shows transcription progress in real-time.
-   **Elegant UI**: Native macOS look and feel with a refined popover for settings and status.
-   **Whisper Integration**: Supports multiple Whisper models (Small, Base, Tiny) for optimal performance.
-   **Intelligent Audio Routing**: Optimized for "Clamshell Mode". Automatically switches to your iPhone microphone via Continuity when the Mac lid is closed and the built-in mic is disabled.

## 🚀 Getting Started

### Prerequisites

-   macOS 15.0 or later.
-   Xcode 16.0 or later.

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/princeniu/SayIt.git
    cd SayIt
    ```

2.  **Initialize Submodules**:
    SayIt uses `whisper.cpp` as a submodule.
    ```bash
    git submodule update --init --recursive
    ```

3.  **Open in Xcode**:
    ```bash
    open SayIt/SayIt.xcodeproj
    ```

4.  **Build and Run**:
    Select the **SayIt** scheme and press `⌘R`.

## 🛠 Usage

1.  **Grant Permissions**: On first launch, SayIt will request Microphone and Speech Recognition permissions.
2.  **Download Model**: If using Whisper for the first time, download the recommended model via the popover.
3.  **Record**: Press `⌥ Space` to start recording. A level indicator will appear in the menu bar.
4.  **Stop**: Press `⌥ Space` again. Transcription starts automatically.
5.  **Paste**: Once the HUD shows "Copied!", your text is in the clipboard. Just `⌘V` where you need it.

## 🏗 Architecture

SayIt is built with modern Apple technologies:
-   **SwiftUI**: For a fluid, reactive user interface.
-   **Combine**: For robust state management and asynchronous data flow.
-   **whisper.cpp**: High-performance C++ implementation of OpenAI's Whisper.
-   **CoreAudio**: For low-latency audio capture.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the Project.
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the Branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

### Running Tests
```bash
xcodebuild -project SayIt/SayIt.xcodeproj -scheme SayIt test
```

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  Made with ❤️ for the macOS Community.
</p>
