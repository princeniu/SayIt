import CoreAudio
import Foundation

public enum AppIntent: Equatable {
    case startRecording
    case stopAndTranscribe
    case cancelRecording
    case retryTranscribe
    case selectMic(AudioDeviceID)
    case openSettings
    case openSettingsWindow
}
