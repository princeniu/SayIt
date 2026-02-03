# SayIt 菜单栏听写工具 PRD

## 背景
SayIt 是一个 macOS 菜单栏常驻听写工具，采用 Swift + SwiftUI 原生实现。目标是“像系统工具一样稳定、极简、可靠”。

## 目标
- 单一 Toggle 交互：开始录音 → 结束并转写 → 自动复制 → HUD/Toast。
- 麦克风选择像 Zoom 一样可靠，支持动态设备变化与断开 fallback。
- 默认 Apple Speech（系统引擎），Whisper 仅预留接口。
- 完全离线：App 不主动联网；系统级服务行为不由 App 控制。

## 非目标
- 按住说话
- 自动开始/自动结束
- 复杂主窗口
- 云端上传
- Whisper 实现（仅占位）

## 关键体验
- Popover 不抢焦点。
- 状态区为“主状态词 + 次级解释”一行。
- Copied 仅用 HUD/Toast，Popover 状态回到 Ready。
- Error 主按钮始终为 Start Recording，错误动作为次按钮。
- Recording 支持 Cancel（丢弃音频，不转写）。
- Transcribing 支持 isSlow 标志；不会因为 5 秒进入 Error。

## 历史记录
- 本地保存（Application Support）。
- 仅保存文本，不保存音频。
- 保留最近 7 天或最多 N 条（默认 100），先到为准。
- 每次转写只复制本次录音的完整结果；历史仅用于回看/手动复制。

## 模块与架构
- UI 只发送 intent；由 AppController/StateMachineRunner 负责 reducer + side effects。
- 模块：PermissionManager / AudioDeviceManager / AudioCaptureEngine / TranscriptionEngine / ClipboardManager / HistoryStore / HUDManager。

## 状态机
Idle / Recording / Transcribing(isSlow) / Copied(瞬时) / Error

## 验收标准（总体）
- 结束并转写在 5 秒内完成复制（正常场景）。
- 设备断开可恢复，错误提示明确。
- 不做任何主动联网请求。
