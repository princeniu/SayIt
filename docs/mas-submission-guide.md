# SayIt Mac App Store (MAS) 上架详细指南 🍏

本指南将协助您将 SayIt 提交至苹果商店。我们已经处理了代码层的解耦，接下来的步骤主要在 Xcode 和 App Store Connect 后台完成。

---

## 第一阶段：Xcode 项目配置

### 1. 添加编译标志 (APP_STORE)
为了剔除 Sparkle，我们需要在 Xcode 中激活宏：
1. 在 Xcode 中点击项目文件 `SayIt`。
2. 选择 **SayIt** Target -> **Build Settings**。
3. 搜索 `Active Compilation Conditions`。
4. 在该项下添加 `APP_STORE`（建议为您专门创建一个名为 "App Store" 的 Build Configuration，或者直接加在 Release 后面）。

### 2. 切换证书
1. 进入 **Signing & Capabilities**。
2. 将 **Signing Certificate** 从 `Developer ID Application` 切换为 `Apple Distribution`。
3. 确保 **App Sandbox** 和 **Audio Input** 权限已勾选（我们已经配好，只需检查）。

---

## 第二阶段：App Store Connect 准备

### 1. 创建 App 记录
1. 登录 [App Store Connect](https://appstoreconnect.apple.com/)。
2. 点击 "我的 App" -> "+" -> "新建 App"。
3. **名称**: SayIt Now - AI Voice to Text。
4. **套装 ID (Bundle ID)**: 确保与 Xcode 中的 `com.princeniu.SayIt` 一致。

### 2. 填写元数据
使用我为您生成的 `docs/app-store-metadata.md`：
- 复制中英文的描述、关键词、副标题。
- **隐私政策 URL**: 填写您 GitHub 上的链接： `https://github.com/princeniu/SayIt/blob/main/docs/privacy-policy.md`。

---

## 第三阶段：打包与上传

### 1. 生成 Archive
1. 在 Xcode 顶部选择 **Any Mac (Apple Silicon, Intel)**。
2. 菜单栏点击 **Product** -> **Archive**。

### 2. 验证并分发
1. 在弹出的 Organizer 窗口，选择最新的 Archive。
2. 点击 **Validate App**（验证 App 是否符合沙盒等规范）。
3. 如果验证通过，点击 **Distribute App** -> **App Store Connect** -> **Upload**。

---

## 第四阶段：提交审核

1. 上传成功后，回到 App Store Connect 后台。
2. 在“构建版本”部分，选择您刚才上传的包。
3. 确认所有分级信息（SayIt 属于无限制内容）。
4. 点击右上角的 **提交以供审核 (Submit for Review)**。

---

## 🏆 常见问题与建议
- **沙盒报错**：MAS 要求极其严格，如果审核退回说无法访问麦克风，请确保 Info.plist 里的 `NSMicrophoneUsageDescription` 描述足够真诚。
- **双线更新**：
  - **官网版 (DMG)**：继续运行 `./scripts/package-release.sh`，它会自动包含 Sparkle。
  - **商店版**：通过 Xcode Archive 上传。

祝您上架顺利！如有任何报错，请截屏告诉我。🤝✨
