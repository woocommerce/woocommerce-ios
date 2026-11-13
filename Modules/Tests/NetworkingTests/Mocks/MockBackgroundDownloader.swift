import Foundation
import Networking
import Synchronization

/// Mock implementation of BackgroundDownloadProtocol for unit testing.
final class MockBackgroundDownloader: BackgroundDownloadProtocol {
    private struct State {
        var downloadResult: Result<BackgroundDownloadResult, Error> = .failure(BackgroundDownloadError.fileNotFound)
        var downloadCallCount = 0
        var lastDownloadURL: URL?
        var lastSessionIdentifier: String?
        var lastAllowCellular: Bool?
        var backgroundCompletionHandler: (@Sendable () -> Void)?
        var cancelCallCount = 0
        var lastCancelledSessionIdentifier: String?
        var reconnectSessionCallCount = 0
        var lastReconnectSessionIdentifier: String?
        var mockFileURL: URL?
        var onDownloadStarted: (@Sendable () -> Void)?
    }

    private let state = Mutex(State())

    var downloadResult: Result<BackgroundDownloadResult, Error> {
        get { state.withLock { $0.downloadResult } }
        set { state.withLock { $0.downloadResult = newValue } }
    }

    var downloadCallCount: Int {
        get { state.withLock { $0.downloadCallCount } }
        set { state.withLock { $0.downloadCallCount = newValue } }
    }

    var lastDownloadURL: URL? {
        get { state.withLock { $0.lastDownloadURL } }
        set { state.withLock { $0.lastDownloadURL = newValue } }
    }

    var lastSessionIdentifier: String? {
        get { state.withLock { $0.lastSessionIdentifier } }
        set { state.withLock { $0.lastSessionIdentifier = newValue } }
    }

    var lastAllowCellular: Bool? {
        get { state.withLock { $0.lastAllowCellular } }
        set { state.withLock { $0.lastAllowCellular = newValue } }
    }

    var backgroundCompletionHandler: (@Sendable () -> Void)? {
        get { state.withLock { $0.backgroundCompletionHandler } }
        set { state.withLock { $0.backgroundCompletionHandler = newValue } }
    }

    var cancelCallCount: Int {
        get { state.withLock { $0.cancelCallCount } }
        set { state.withLock { $0.cancelCallCount = newValue } }
    }

    var lastCancelledSessionIdentifier: String? {
        get { state.withLock { $0.lastCancelledSessionIdentifier } }
        set { state.withLock { $0.lastCancelledSessionIdentifier = newValue } }
    }

    var reconnectSessionCallCount: Int {
        get { state.withLock { $0.reconnectSessionCallCount } }
        set { state.withLock { $0.reconnectSessionCallCount = newValue } }
    }

    var lastReconnectSessionIdentifier: String? {
        get { state.withLock { $0.lastReconnectSessionIdentifier } }
        set { state.withLock { $0.lastReconnectSessionIdentifier = newValue } }
    }

    var mockFileURL: URL? {
        get { state.withLock { $0.mockFileURL } }
        set { state.withLock { $0.mockFileURL = newValue } }
    }

    var onDownloadStarted: (@Sendable () -> Void)? {
        get { state.withLock { $0.onDownloadStarted } }
        set { state.withLock { $0.onDownloadStarted = newValue } }
    }

    private let temporaryDirectory: URL

    init(fileManager: FileManager = .default) {
        temporaryDirectory = fileManager.temporaryDirectory
    }

    // MARK: - BackgroundDownloadProtocol

    func downloadFile(from url: URL, sessionIdentifier: String, allowCellular: Bool) async throws -> BackgroundDownloadResult {
        let onDownloadStarted = state.withLock {
            $0.downloadCallCount += 1
            $0.lastDownloadURL = url
            $0.lastSessionIdentifier = sessionIdentifier
            $0.lastAllowCellular = allowCellular
            return $0.onDownloadStarted
        }

        // Invoke outside the lock so tests can inspect or configure the mock from the callback.
        onDownloadStarted?()
        return try downloadResult.get()
    }

    func setBackgroundCompletionHandler(_ completionHandler: @escaping @Sendable () -> Void) {
        backgroundCompletionHandler = completionHandler
    }

    func reconnectToSession(identifier sessionIdentifier: String,
                           allowCellular: Bool,
                           completionHandler: @escaping @Sendable () -> Void) async -> URL? {
        state.withLock {
            $0.reconnectSessionCallCount += 1
            $0.lastReconnectSessionIdentifier = sessionIdentifier
            $0.backgroundCompletionHandler = completionHandler
            return $0.mockFileURL
        }
    }

    func cancelDownloads(for sessionIdentifier: String) async {
        state.withLock {
            $0.cancelCallCount += 1
            $0.lastCancelledSessionIdentifier = sessionIdentifier
        }
    }
}

// MARK: - Mock Helpers

extension MockBackgroundDownloader {
    /// Configure the mock to return a successful download with the given file URL
    func mockSuccessfulDownload(fileURL: URL) {
        downloadResult = .success(.init(fileURL: fileURL,
                                        statusCode: 200,
                                        contentType: "application/json"))
    }

    /// Configure the mock to return a successful download with response metadata.
    func mockSuccessfulDownload(fileURL: URL, statusCode: Int?, contentType: String?) {
        downloadResult = .success(.init(fileURL: fileURL,
                                        statusCode: statusCode,
                                        contentType: contentType))
    }

    /// Configure the mock to return a failed download with the given error
    func mockFailedDownload(error: Error) {
        downloadResult = .failure(error)
    }

    /// Reset all mock state
    func reset() {
        state.withLock { $0 = State() }
    }

    /// Simulate calling the background completion handler
    func simulateBackgroundCompletion() {
        backgroundCompletionHandler?()
    }

    /// Create a temporary file with test data for mock downloads
    func createMockDownloadFile(withContent content: String) -> URL {
        let fileName = "mock_download_\(UUID().uuidString).json"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }
}
