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

    func start(url: URL) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        task = session.downloadTask(with: url)
        status = .downloading(0)
        task?.resume()
    }

    func cancel() {
        task?.cancel()
        status = .canceled
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        status = .completed(location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            status = .failed(error.localizedDescription)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        status = .downloading(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }
}
