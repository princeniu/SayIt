import AVFoundation
import AudioToolbox
import CoreAudio

protocol AudioCaptureEngineProtocol: AnyObject {
    func start(deviceID: AudioDeviceID?) throws
    func stopAndFinalize() throws -> AVAudioPCMBuffer
    func cancel()
    var onFirstBuffer: (() -> Void)? { get set }
}

final class AudioCaptureEngine: AudioCaptureEngineProtocol {
    enum CaptureError: Error {
        case alreadyRunning
        case notRunning
        case unsupportedFormat
        case unableToSetDevice
    }

    private let engine: AVAudioEngine
    private var captureFormat: AVAudioFormat?
    private var buffers: [AVAudioPCMBuffer] = []
    private var isRunning = false
    private let bufferLock = NSLock()
    var onFirstBuffer: (() -> Void)?
    private var didEmitFirstBuffer = false

    init(engine: AVAudioEngine = AVAudioEngine()) {
        self.engine = engine
    }

    func start(deviceID: AudioDeviceID?) throws {
        guard !isRunning else { throw CaptureError.alreadyRunning }
        buffers.removeAll()
        didEmitFirstBuffer = false

        let inputNode = engine.inputNode
        if let deviceID {
            guard let audioUnit = inputNode.audioUnit else {
                throw CaptureError.unableToSetDevice
            }
            var selectedID = deviceID
            let size = UInt32(MemoryLayout<AudioDeviceID>.size)
            let status = AudioUnitSetProperty(
                audioUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &selectedID,
                size
            )
            guard status == noErr else {
                throw CaptureError.unableToSetDevice
            }
        }
        let format = inputNode.inputFormat(forBus: 0)
        captureFormat = format

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.append(buffer)
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stopAndFinalize() throws -> AVAudioPCMBuffer {
        guard isRunning else { throw CaptureError.notRunning }
        isRunning = false
        didEmitFirstBuffer = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        guard let format = captureFormat else { throw CaptureError.notRunning }
        return try combine(buffers: buffers, format: format)
    }

    func cancel() {
        buffers.removeAll()
        captureFormat = nil
        didEmitFirstBuffer = false
        if isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            isRunning = false
        }
    }

    private func append(_ buffer: AVAudioPCMBuffer) {
        if !didEmitFirstBuffer {
            didEmitFirstBuffer = true
            let handler = onFirstBuffer
            DispatchQueue.main.async {
                handler?()
            }
        }
        guard let copy = copyBuffer(buffer) else { return }
        bufferLock.lock()
        buffers.append(copy)
        bufferLock.unlock()
    }

    private func copyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let frameLength = buffer.frameLength
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frameLength) else {
            return nil
        }
        copy.frameLength = frameLength

        if buffer.format.isInterleaved {
            let srcList = buffer.audioBufferList.pointee
            let dstList = copy.audioBufferList.pointee
            guard srcList.mNumberBuffers == dstList.mNumberBuffers else { return nil }
            for _ in 0..<Int(srcList.mNumberBuffers) {
                let srcBuffer = srcList.mBuffers
                let dstBuffer = dstList.mBuffers
                guard let srcData = srcBuffer.mData, let dstData = dstBuffer.mData else { return nil }
                memcpy(dstData, srcData, Int(srcBuffer.mDataByteSize))
            }
            return copy
        }

        switch buffer.format.commonFormat {
        case .pcmFormatFloat32:
            guard let src = buffer.floatChannelData, let dst = copy.floatChannelData else { return nil }
            let channels = Int(buffer.format.channelCount)
            let frames = Int(frameLength)
            for channel in 0..<channels {
                memcpy(dst[channel], src[channel], frames * MemoryLayout<Float>.size)
            }
            return copy
        case .pcmFormatInt16:
            guard let src = buffer.int16ChannelData, let dst = copy.int16ChannelData else { return nil }
            let channels = Int(buffer.format.channelCount)
            let frames = Int(frameLength)
            for channel in 0..<channels {
                memcpy(dst[channel], src[channel], frames * MemoryLayout<Int16>.size)
            }
            return copy
        default:
            return nil
        }
    }

    private func combine(buffers: [AVAudioPCMBuffer], format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let totalFrames = buffers.reduce(0) { $0 + $1.frameLength }
        let capacity = max(totalFrames, 1)
        guard let result = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw CaptureError.unsupportedFormat
        }
        result.frameLength = totalFrames
        guard totalFrames > 0 else { return result }

        if format.isInterleaved {
            return try combineInterleaved(buffers: buffers, format: format, into: result)
        }

        switch format.commonFormat {
        case .pcmFormatFloat32:
            return try combineFloat32(buffers: buffers, format: format, into: result)
        case .pcmFormatInt16:
            return try combineInt16(buffers: buffers, format: format, into: result)
        default:
            throw CaptureError.unsupportedFormat
        }
    }

    private func combineFloat32(
        buffers: [AVAudioPCMBuffer],
        format: AVAudioFormat,
        into result: AVAudioPCMBuffer
    ) throws -> AVAudioPCMBuffer {
        guard let dst = result.floatChannelData else { throw CaptureError.unsupportedFormat }
        let channels = Int(format.channelCount)
        var frameOffset: AVAudioFrameCount = 0

        for buffer in buffers {
            guard let src = buffer.floatChannelData else { continue }
            let frames = Int(buffer.frameLength)
            for channel in 0..<channels {
                let destPointer = dst[channel].advanced(by: Int(frameOffset))
                memcpy(destPointer, src[channel], frames * MemoryLayout<Float>.size)
            }
            frameOffset += buffer.frameLength
        }
        return result
    }

    private func combineInt16(
        buffers: [AVAudioPCMBuffer],
        format: AVAudioFormat,
        into result: AVAudioPCMBuffer
    ) throws -> AVAudioPCMBuffer {
        guard let dst = result.int16ChannelData else { throw CaptureError.unsupportedFormat }
        let channels = Int(format.channelCount)
        var frameOffset: AVAudioFrameCount = 0

        for buffer in buffers {
            guard let src = buffer.int16ChannelData else { continue }
            let frames = Int(buffer.frameLength)
            for channel in 0..<channels {
                let destPointer = dst[channel].advanced(by: Int(frameOffset))
                memcpy(destPointer, src[channel], frames * MemoryLayout<Int16>.size)
            }
            frameOffset += buffer.frameLength
        }
        return result
    }

    private func combineInterleaved(
        buffers: [AVAudioPCMBuffer],
        format: AVAudioFormat,
        into result: AVAudioPCMBuffer
    ) throws -> AVAudioPCMBuffer {
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        var frameOffset: AVAudioFrameCount = 0

        let dstBufferList = result.audioBufferList.pointee
        guard dstBufferList.mNumberBuffers == 1 else { throw CaptureError.unsupportedFormat }
        guard let dstData = dstBufferList.mBuffers.mData else { throw CaptureError.unsupportedFormat }

        for buffer in buffers {
            let srcList = buffer.audioBufferList.pointee
            guard srcList.mNumberBuffers == 1 else { continue }
            guard let srcData = srcList.mBuffers.mData else { continue }
            let srcBytes = Int(buffer.frameLength) * bytesPerFrame
            let destOffset = Int(frameOffset) * bytesPerFrame
            memcpy(dstData.advanced(by: destOffset), srcData, srcBytes)
            frameOffset += buffer.frameLength
        }
        return result
    }
}
