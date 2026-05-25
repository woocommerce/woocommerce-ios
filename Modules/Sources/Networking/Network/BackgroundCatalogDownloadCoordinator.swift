import Foundation
import CocoaLumberjackSwift

/// Resumes parse + persist of a catalog file that was staged in a previous session
/// but never finished its write transaction. The download itself is already complete —
/// only the parse step is retried.
public protocol BackgroundCatalogParseResuming {
    func resumePendingParseIfNeeded(parseHandler: @escaping (URL, Int64) async throws -> Void) async
}

/// Coordinates background catalog downloads, including handling app wake events.
public class BackgroundCatalogDownloadCoordinator: BackgroundCatalogParseResuming {
    private let backgroundDownloader: BackgroundDownloadProtocol
    private let fileManager: FileManager
    private let pendingCatalogFileStore: PendingCatalogFileStore
    private let backgroundDownloadStateStore: BackgroundDownloadStateStore

    public init(backgroundDownloader: BackgroundDownloadProtocol = BackgroundDownloadService(),
                fileManager: FileManager = .default,
                pendingCatalogFileStore: PendingCatalogFileStore = .init(),
                backgroundDownloadStateStore: BackgroundDownloadStateStore = .init()) {
        self.backgroundDownloader = backgroundDownloader
        self.fileManager = fileManager
        self.pendingCatalogFileStore = pendingCatalogFileStore
        self.backgroundDownloadStateStore = backgroundDownloadStateStore
    }

    /// Handles a background URLSession wake event.
    /// Called from AppDelegate when iOS wakes the app for a completed download.
    ///
    /// Stages the downloaded file under Caches/ before attempting parse + persist, so that
    /// if the 30s background window is exceeded (or the parse throws), the file survives
    /// for a retry via `resumePendingParseIfNeeded` on the next foreground entry.
    /// - Parameters:
    ///   - sessionIdentifier: The session identifier from the callback
    ///   - completionHandler: Completion handler to call when processing is done
    ///   - parseHandler: Closure to parse and persist the downloaded file
    public func handleBackgroundSessionEvent(
        sessionIdentifier: String,
        completionHandler: @escaping () -> Void,
        parseHandler: @escaping (URL, Int64) async throws -> Void
    ) async {
        DDLogInfo("🟣 Handling background session event for: \(sessionIdentifier)")

        // Load the saved download state to know which site this is for
        guard let state = backgroundDownloadStateStore.load(for: sessionIdentifier) else {
            DDLogError("⛔️ No saved state found for background download session: \(sessionIdentifier)")
            completionHandler()
            return
        }

        // Reconnect to the background session and get the downloaded file
        guard let fileURL = await backgroundDownloader.reconnectToSession(identifier: sessionIdentifier,
                                                                          allowCellular: true,
                                                                          completionHandler: completionHandler) else {
            DDLogError("⛔️ Failed to reconnect to background download session")
            backgroundDownloadStateStore.clear()
            return
        }

        DDLogInfo("🟣 Background download file ready at: \(fileURL.path)")

        // Move to a durable staging path so the file survives if parse + persist is killed
        // by iOS. We retry on next foreground.
        let stagedURL: URL
        do {
            stagedURL = try stageDownloadedFile(fileURL, siteID: state.siteID)
            pendingCatalogFileStore.save(.init(filePath: stagedURL.path, siteID: state.siteID))
            DDLogInfo("🟣 Staged background catalog at: \(stagedURL.path)")
        } catch {
            DDLogError("⛔️ Failed to stage background download: \(error). Falling back to original URL.")
            // If staging fails we still attempt parse from the temp URL
            // Result ignored: no staged file was written, so there's nothing to clean up either way.
            _ = await runParse(url: fileURL, siteID: state.siteID, parseHandler: parseHandler)
            backgroundDownloadStateStore.clear()
            return
        }

        // Attempt parse + persist within the 30s window.
        let success = await runParse(url: stagedURL, siteID: state.siteID, parseHandler: parseHandler)

        if success {
            try? fileManager.removeItem(at: stagedURL)
            pendingCatalogFileStore.clear()
        }
        // On failure: leave the staged file + pending record so the next foreground entry retries.
        backgroundDownloadStateStore.clear()
    }

    /// Retries the parse step for a previously-staged catalog file, if one exists.
    /// The download itself already completed in a prior session — this only re-parses
    /// the file on disk. Called on POS foreground entry — no iOS execution-time pressure here.
    /// Errors are logged but swallowed so normal sync can proceed.
    public func resumePendingParseIfNeeded(
        parseHandler: @escaping (URL, Int64) async throws -> Void
    ) async {
        guard let pending = pendingCatalogFileStore.load() else {
            return
        }

        let fileURL = URL(fileURLWithPath: pending.filePath)

        guard fileManager.fileExists(atPath: pending.filePath) else {
            DDLogWarn("⚠️ Pending catalog file missing at \(pending.filePath); clearing record")
            pendingCatalogFileStore.clear()
            return
        }

        DDLogInfo("🟣 Resuming pending catalog persist for site \(pending.siteID) from \(pending.filePath)")
        let success = await runParse(url: fileURL, siteID: pending.siteID, parseHandler: parseHandler)

        if success {
            try? fileManager.removeItem(at: fileURL)
            pendingCatalogFileStore.clear()
        }
        // On failure: leave file + record in place for the next foreground entry.
    }
}

private extension BackgroundCatalogDownloadCoordinator {
    func runParse(url: URL,
                  siteID: Int64,
                  parseHandler: @escaping (URL, Int64) async throws -> Void) async -> Bool {
        do {
            try await parseHandler(url, siteID)
            DDLogInfo("✅ Background catalog processing completed successfully")
            return true
        } catch {
            DDLogError("⛔️ Failed to process catalog in background: \(error)")
            return false
        }
    }

    func stageDownloadedFile(_ sourceURL: URL, siteID: Int64) throws -> URL {
        let directory = try pendingCatalogDirectory()
        let destination = directory.appendingPathComponent("catalog-\(siteID)-\(UUID().uuidString).json")
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: sourceURL, to: destination)
        return destination
    }

    func pendingCatalogDirectory() throws -> URL {
        let caches = try fileManager.url(for: .cachesDirectory,
                                         in: .userDomainMask,
                                         appropriateFor: nil,
                                         create: true)
        let directory = caches.appendingPathComponent("POSPendingCatalog", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
