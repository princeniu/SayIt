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

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil {
            return
        }
        menuBarController = MenuBarController()
    }
}
