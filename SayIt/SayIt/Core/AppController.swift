import Combine
import Foundation

public final class AppController: ObservableObject {
    @Published public private(set) var state = AppState()

    public init() {}

    public func send(_ intent: AppIntent) {
        switch intent {
        case .startRecording:
            state.mode = .recording
        }
    }
}
