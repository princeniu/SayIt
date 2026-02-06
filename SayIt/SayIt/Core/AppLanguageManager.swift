import Foundation
import SwiftUI
import Combine

/// 管理 App 语言和本地化 Bundle
final class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()
    @Published var currentLanguage: String
    private let userDefaultsKey = "appLanguage"

    private init() {
        let lang = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "system"
        self.currentLanguage = lang
    }

    /// 当前正在使用的 Locale（供 SwiftUI .environment(\.locale) 使用）
    var currentLocale: Locale {
        let id = currentLanguage == "system" ? Locale.current.identifier : currentLanguage
        return Locale(identifier: id)
    }

    /// 当前正在使用的本地化 Bundle
    var bundle: Bundle {
        guard currentLanguage != "system" else {
            return Bundle.main
        }
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }

    /// 通用字符串本地化获取方法
    func localized(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }

    /// 手动切换语言
    func setLanguage(_ language: String) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: userDefaultsKey)
        // 可发出通知让界面刷新
        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("AppLanguageDidChange")
}

/// 作为 Popover 根视图，观察语言变化并向下传递 locale，使切换语言后整棵视图树更新
struct PopoverRootView: View {
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @EnvironmentObject var appController: AppController
    var body: some View {
        ContentView()
            .environmentObject(appController)
            .environment(\.locale, languageManager.currentLocale)
    }
}

/// 用于 SwiftUI 的动态本地化文本组件
struct LocalizedText: View {
    @ObservedObject private var languageManager = AppLanguageManager.shared
    let key: String
    var body: some View {
        Text(languageManager.localized(key))
    }
}

