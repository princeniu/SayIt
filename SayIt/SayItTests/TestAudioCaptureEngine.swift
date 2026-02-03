import AVFoundation
import CoreAudio
@testable import SayIt

final class TestAudioCaptureEngine: AudioCaptureEngineProtocol {
    private(set) var startCalled = false
    private(set) var stopCalled = false
    private(set) var cancelCalled = false
    private(set) var lastStartDeviceID: AudioDeviceID?
    var bufferToReturn: AVAudioPCMBuffer?

    func start(deviceID: AudioDeviceID?) throws {
        startCalled = true
        lastStartDeviceID = deviceID
    }

    func stopAndFinalize() throws -> AVAudioPCMBuffer {
        stopCalled = true
        if let buffer = bufferToReturn {
            return buffer
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        guard let format else {
            throw NSError(domain: "TestAudioCaptureEngine", code: 1)
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1) else {
            throw NSError(domain: "TestAudioCaptureEngine", code: 2)
        }
        buffer.frameLength = 0
        return buffer
    }

    func cancel() {
        cancelCalled = true
    }
}
