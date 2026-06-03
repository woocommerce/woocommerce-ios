// periphery:ignore:all
import Foundation

/// Protocol for handling background downloads with app suspension support.
public protocol BackgroundDownloadProtocol {
    /// Downloads a file from the specified URL in the background.
    /// - Parameters:
    ///   - url: The URL to download from.
    ///   - sessionIdentifier: Unique identifier for the background session.
    ///   - allowCellular: Whether cellular data should be allowed for this download.
    /// - Returns: Local file URL where the downloaded content is stored, plus response metadata.
    func downloadFile(from url: URL, sessionIdentifier: String, allowCellular: Bool) async throws -> BackgroundDownloadResult

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

/// Result of a completed background download.
public struct BackgroundDownloadResult {
    public let fileURL: URL
    public let statusCode: Int?
    public let contentType: String?
    public let bytesDownloaded: Int64
    public let totalBytesExpected: Int64

    public init(fileURL: URL,
                statusCode: Int?,
                contentType: String?,
                bytesDownloaded: Int64,
                totalBytesExpected: Int64) {
        self.fileURL = fileURL
        self.statusCode = statusCode
        self.contentType = contentType
        self.bytesDownloaded = bytesDownloaded
        self.totalBytesExpected = totalBytesExpected
    }
}

/// Errors that can occur during background downloads.
public enum BackgroundDownloadError: Error, LocalizedError, Equatable {
    case invalidURL
    case sessionCreationFailed
    case unacceptableStatusCode(statusCode: Int, contentType: String?)
    case downloadFailed(Error)
    case fileNotFound
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .sessionCreationFailed:
            return "Failed to create background download session"
        case .unacceptableStatusCode(let statusCode, _):
            return "Download failed with HTTP status \(statusCode)"
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
        case (.unacceptableStatusCode(let lhsStatusCode, let lhsContentType), .unacceptableStatusCode(let rhsStatusCode, let rhsContentType)):
            return lhsStatusCode == rhsStatusCode && lhsContentType == rhsContentType
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

extension BackgroundDownloadError {
    var statusCode: Int? {
        switch self {
        case .unacceptableStatusCode(let statusCode, _):
            return statusCode
        default:
            return nil
        }
    }

    var contentType: String? {
        switch self {
        case .unacceptableStatusCode(_, let contentType):
            return contentType
        default:
            return nil
        }
    }
}
