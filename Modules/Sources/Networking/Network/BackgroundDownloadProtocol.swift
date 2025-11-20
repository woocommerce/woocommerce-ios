// periphery:ignore:all
import Foundation

/// Protocol for handling background downloads with app suspension support.
public protocol BackgroundDownloadProtocol {
    /// Downloads a file from the specified URL in the background.
    /// - Parameters:
    ///   - url: The URL to download from.
    ///   - sessionIdentifier: Unique identifier for the background session.
    ///   - allowCellular: Whether cellular data should be allowed for this download.
    /// - Returns: Local file URL where the downloaded content is stored.
    func downloadFile(from url: URL, sessionIdentifier: String, allowCellular: Bool) async throws -> URL

    /// Sets up background app suspension handling.
    /// - Parameter completionHandler: Handler to call when background download completes.
    func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void)

    /// Reconnects to an existing background session after app wake.
    /// Call this from AppDelegate when iOS wakes the app for background URLSession events.
    /// - Parameters:
    ///   - sessionIdentifier: The session identifier from the callback
    ///   - allowCellular: Whether cellular data should be allowed
    ///   - completionHandler: Completion handler to call when all events are processed
    /// - Returns: Downloaded file URL if download completed, nil if still in progress
    func reconnectToSession(identifier sessionIdentifier: String,
                           allowCellular: Bool,
                           completionHandler: @escaping () -> Void) async -> URL?

    /// Cancels all active downloads for the session.
    /// - Parameter sessionIdentifier: The session identifier to cancel.
    func cancelDownloads(for sessionIdentifier: String) async
}

/// Progress and status information for background downloads.
public struct BackgroundDownloadProgress {
    public let bytesDownloaded: Int64
    public let totalBytes: Int64
    public let progress: Double

    public init(bytesDownloaded: Int64, totalBytes: Int64) {
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.progress = totalBytes > 0 ? Double(bytesDownloaded) / Double(totalBytes) : 0.0
    }
}

/// Errors that can occur during background downloads.
public enum BackgroundDownloadError: Error, LocalizedError, Equatable {
    case invalidURL
    case sessionCreationFailed
    case downloadFailed(Error)
    case fileNotFound
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .sessionCreationFailed:
            return "Failed to create background download session"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .fileNotFound:
            return "Downloaded file not found"
        case .cancelled:
            return "Download was cancelled"
        }
    }

    public static func == (lhs: BackgroundDownloadError, rhs: BackgroundDownloadError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.sessionCreationFailed, .sessionCreationFailed):
            return true
        case (.downloadFailed(let lhsError), .downloadFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.fileNotFound, .fileNotFound):
            return true
        case (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
}
