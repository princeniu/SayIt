import AVFoundation
import Speech

final class AppleSpeechEngine: TranscriptionEngine {
    func transcribe(buffer: AVAudioPCMBuffer, locale: Locale) async throws -> String {
        if buffer.frameLength == 0 {
            return ""
        }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw TranscriptionError.notAuthorized
        }

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        request.append(buffer)
        request.endAudio()

        return try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            let task = recognizer.recognitionTask(with: request) { result, error in
                if didResume { return }
                if let error {
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else { return }
                if result.isFinal {
                    didResume = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
            if task.state == .canceling {
                if !didResume {
                    didResume = true
                    continuation.resume(throwing: TranscriptionError.failed)
                }
            }
        }
    }
}
