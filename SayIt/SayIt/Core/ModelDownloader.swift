import Foundation

final class ModelDownloader: NSObject, URLSessionDownloadDelegate {
    enum Status: Equatable {
        case idle
        case downloading(Double)
        case completed(URL)
        case failed(String)
        case canceled
    }

    private(set) var status: Status = .idle
    private var task: URLSessionDownloadTask?
    var onProgress: ((Double) -> Void)?
    var onCompleted: ((URL) -> Void)?
    var onFailed: ((String) -> Void)?
    var onCanceled: (() -> Void)?

    func start(url: URL) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        task = session.downloadTask(with: url)
        status = .downloading(0)
        onProgress?(0)
        task?.resume()
    }

    func cancel() {
        task?.cancel()
        status = .canceled
        onCanceled?()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        status = .completed(location)
        onCompleted?(location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            status = .failed(error.localizedDescription)
            onFailed?(error.localizedDescription)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        status = .downloading(progress)
        onProgress?(progress)
    }
}
