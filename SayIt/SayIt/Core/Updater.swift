import Foundation
#if canImport(Sparkle)
import Sparkle
#endif

final class Updater: NSObject {
    #if !APP_STORE && canImport(Sparkle)
    private let updaterController: SPUStandardUpdaterController
    #endif

    override init() {
        #if !APP_STORE && canImport(Sparkle)
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        #endif
        super.init()
    }

    func checkForUpdates() {
        #if !APP_STORE && canImport(Sparkle)
        updaterController.checkForUpdates(nil)
        #else
        print("Updates disabled for App Store or Sparkle not available")
        #endif
    }
}
