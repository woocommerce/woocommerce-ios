import CocoaLumberjackSwift
import Foundation

/// Service for handling background downloads using `URLSessionConfiguration.background`.
/// Follows Apple's guidelines for background downloads with app suspension support.
public class BackgroundDownloadService: NSObject {
    private var backgroundCompletionHandler: (() -> Void)?
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var downloadContinuations: [String: CheckedContinuation<URL, Error>] = [:]
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        super.init()
    }
}

// MARK: - BackgroundDownloadProtocol

extension BackgroundDownloadService: BackgroundDownloadProtocol {
    public func downloadFile(from url: URL, sessionIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = createBackgroundSession(identifier: sessionIdentifier)
            let downloadTask = session.downloadTask(with: url)

            // Stores the continuation for later use in delegate methods.
            downloadContinuations[sessionIdentifier] = continuation
            downloadTasks[sessionIdentifier] = downloadTask

            downloadTask.resume()
        }
    }

    public func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }

    public func cancelDownloads(for sessionIdentifier: String) async {
        if let task = downloadTasks[sessionIdentifier] {
            task.cancel()
            downloadTasks.removeValue(forKey: sessionIdentifier)

            // Resumes continuation with cancellation error.
            if let continuation = downloadContinuations.removeValue(forKey: sessionIdentifier) {
                continuation.resume(throwing: BackgroundDownloadError.cancelled)
            }
        }
    }

    // MARK: - Private Methods

    private func createBackgroundSession(identifier: String) -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)

        // Configure for background downloads as per Apple guidelines
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false  // Don't wait for optimal conditions
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300  // 5 minutes

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    private func handleDownloadCompletion(for sessionIdentifier: String, fileURL: URL?, error: Error?) {
        guard let continuation = downloadContinuations.removeValue(forKey: sessionIdentifier) else {
            return
        }

        downloadTasks.removeValue(forKey: sessionIdentifier)

        if let error {
            continuation.resume(throwing: BackgroundDownloadError.downloadFailed(error))
        } else if let fileURL {
            continuation.resume(returning: fileURL)
        } else {
            continuation.resume(throwing: BackgroundDownloadError.fileNotFound)
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadService: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        // For catalog downloads, reads data directly from temp location to save storage space.
        // This is safe for typical JSON catalog files which are usually < 50MB.
        guard let sessionIdentifier = session.configuration.identifier else {
            DDLogError("🟣 Background download session missing identifier")
            return
        }

        do {
            // Get file size first to make informed decision
            let fileAttributes = try fileManager.attributesOfItem(atPath: location.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0

            // For very large files (>100MB), move to permanent location to avoid memory issues
            if fileSize > 100 * 1024 * 1024 {
                guard let documentsURL = fileManager.urls(for: .documentDirectory,
                                                          in: .userDomainMask).first else {
                    throw BackgroundDownloadError.sessionCreationFailed
                }

                let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "downloaded_catalog"
                let permanentURL = documentsURL.appendingPathComponent(fileName)

                // Remove existing file if it exists
                if fileManager.fileExists(atPath: permanentURL.path) {
                    try fileManager.removeItem(at: permanentURL)
                }

                // Move the downloaded file to permanent location
                try fileManager.moveItem(at: location, to: permanentURL)

                handleDownloadCompletion(for: sessionIdentifier,
                                         fileURL: permanentURL,
                                         error: nil)
            } else {
                // For smaller files, returns the temporary location directly.
                // The parsing code will handle cleanup, and iOS will auto-clean temp files.
                handleDownloadCompletion(for: sessionIdentifier,
                                         fileURL: location,
                                         error: nil)
            }
        } catch {
            handleDownloadCompletion(for: sessionIdentifier,
                                     fileURL: nil,
                                     error: error)
        }
    }

    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        let progress = BackgroundDownloadProgress(
            bytesDownloaded: totalBytesWritten,
            totalBytes: totalBytesExpectedToWrite
        )

        // For now, the download progress is logged.
        // We might want to notify observers to update UI on progress changes.
        if totalBytesExpectedToWrite > 0 {
            let percentComplete = Int(progress.progress * 100)
            DDLogInfo("🟣 Download progress: \(percentComplete)%")
        }
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        guard let sessionIdentifier = session.configuration.identifier else {
            DDLogError("🟣 Background download session missing identifier in error handling")
            return
        }

        if let error {
            handleDownloadCompletion(for: sessionIdentifier,
                                     fileURL: nil,
                                     error: error)
        }
    }
}

// MARK: - URLSessionDelegate

extension BackgroundDownloadService: URLSessionDelegate {
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // Executes the background URL session completion handler on the main queue because this method may be called on a secondary queue
        // according to doc:
        // https://developer.apple.com/documentation/foundation/downloading-files-in-the-background#Handle-app-suspension
        DispatchQueue.main.async { [weak self] in
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }
}
