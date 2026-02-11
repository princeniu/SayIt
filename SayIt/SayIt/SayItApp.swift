//
//  SayItApp.swift
//  SayIt
//
//  Created by 牛拙 on 2/2/26.
//

import AppKit
import SwiftUI

@main
struct SayItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some Scene {
        Settings {
            EmptyView()
                .environment(\.locale, Locale(identifier: appLanguage == "system" ? Locale.current.identifier : appLanguage))
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil {
            return
        }
        let appController = AppController()
        menuBarController = MenuBarController(appController: appController)
    }
}
