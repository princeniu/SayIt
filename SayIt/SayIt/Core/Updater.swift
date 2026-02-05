import Foundation
#if canImport(Sparkle)
import Sparkle
#endif

final class Updater: NSObject {
    #if canImport(Sparkle)
    private let updaterController: SPUStandardUpdaterController
    #endif

    override init() {
        #if canImport(Sparkle)
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        #endif
        super.init()
    }

    func checkForUpdates() {
        #if canImport(Sparkle)
        updaterController.checkForUpdates(nil)
        #else
        print("Sparkle not available")
        #endif
    }
}
