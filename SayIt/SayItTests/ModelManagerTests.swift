import Foundation
import Testing
@testable import SayIt

struct ModelManagerTests {
    @Test func modelReady_falseWhenMissingFile() throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = ModelManager(rootURL: temp)
        #expect(manager.isModelReady(WhisperModelType.small) == false)
    }
}
