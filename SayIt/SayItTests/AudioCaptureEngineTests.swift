#if false
import Testing
@testable import SayIt

@Test func audioCaptureEngine_startsAndStops() async throws {
    let engine = AudioCaptureEngine()
    try engine.start()
    _ = try engine.stopAndFinalize()
}
#endif
