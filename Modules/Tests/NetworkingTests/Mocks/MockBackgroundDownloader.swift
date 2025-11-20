import Foundation
import Networking

/// Mock implementation of BackgroundDownloadProtocol for unit testing.
final class MockBackgroundDownloader: BackgroundDownloadProtocol {
    // MARK: - Mock State
    var downloadResult: Result<URL, Error> = .failure(BackgroundDownloadError.fileNotFound)
    var downloadCallCount = 0
    var lastDownloadURL: URL?
    var lastSessionIdentifier: String?
    var lastAllowCellular: Bool?
    var backgroundCompletionHandler: (() -> Void)?
    var cancelCallCount = 0
    var lastCancelledSessionIdentifier: String?
    var reconnectSessionCallCount = 0
    var lastReconnectSessionIdentifier: String?
    var mockFileURL: URL?
    var onDownloadStarted: (() -> Void)?

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    // MARK: - BackgroundDownloadProtocol

    func downloadFile(from url: URL, sessionIdentifier: String, allowCellular: Bool) async throws -> URL {
        downloadCallCount += 1
        lastDownloadURL = url
        lastSessionIdentifier = sessionIdentifier
        lastAllowCellular = allowCellular

        // Notify test that download has started
        onDownloadStarted?()

        switch downloadResult {
        case .success(let fileURL):
            return fileURL
        case .failure(let error):
            throw error
        }
    }

    func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }

    func reconnectToSession(identifier sessionIdentifier: String,
                           allowCellular: Bool,
                           completionHandler: @escaping () -> Void) async -> URL? {
        reconnectSessionCallCount += 1
        lastReconnectSessionIdentifier = sessionIdentifier
        setBackgroundCompletionHandler(completionHandler)
        return mockFileURL
    }

    func cancelDownloads(for sessionIdentifier: String) async {
        cancelCallCount += 1
        lastCancelledSessionIdentifier = sessionIdentifier
    }
}

// MARK: - Mock Helpers

extension MockBackgroundDownloader {
    /// Configure the mock to return a successful download with the given file URL
    func mockSuccessfulDownload(fileURL: URL) {
        downloadResult = .success(fileURL)
    }

    /// Configure the mock to return a failed download with the given error
    func mockFailedDownload(error: Error) {
        downloadResult = .failure(error)
    }

    /// Reset all mock state
    func reset() {
        downloadResult = .failure(BackgroundDownloadError.fileNotFound)
        downloadCallCount = 0
        lastDownloadURL = nil
        lastSessionIdentifier = nil
        lastAllowCellular = nil
        backgroundCompletionHandler = nil
        cancelCallCount = 0
        lastCancelledSessionIdentifier = nil
        reconnectSessionCallCount = 0
        lastReconnectSessionIdentifier = nil
        mockFileURL = nil
        onDownloadStarted = nil
    }

    /// Simulate calling the background completion handler
    func simulateBackgroundCompletion() {
        backgroundCompletionHandler?()
    }

    /// Create a temporary file with test data for mock downloads
    func createMockDownloadFile(withContent content: String) -> URL {
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = "mock_download_\(UUID().uuidString).json"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }
}
