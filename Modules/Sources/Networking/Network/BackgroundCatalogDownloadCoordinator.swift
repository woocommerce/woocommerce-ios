import Foundation
import CocoaLumberjackSwift

/// Coordinates background catalog downloads, including handling app wake events.
public class BackgroundCatalogDownloadCoordinator {
    private let backgroundDownloader: BackgroundDownloadProtocol

    public init(backgroundDownloader: BackgroundDownloadProtocol = BackgroundDownloadService()) {
        self.backgroundDownloader = backgroundDownloader
    }

    /// Handles a background URLSession wake event.
    /// Called from AppDelegate when iOS wakes the app for a completed download.
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
        guard let state = BackgroundDownloadState.load(for: sessionIdentifier) else {
            DDLogError("⛔️ No saved state found for background download session: \(sessionIdentifier)")
            completionHandler()
            return
        }

        // Reconnect to the background session and get the downloaded file
        guard let fileURL = await backgroundDownloader.reconnectToSession(identifier: sessionIdentifier,
                                                                          allowCellular: true,
                                                                          completionHandler: completionHandler) else {
            DDLogError("⛔️ Failed to reconnect to background download session")
            BackgroundDownloadState.clear()
            return
        }

        DDLogInfo("🟣 Background download file ready at: \(fileURL.path)")

        // Parse the catalog file in this background window (~30 seconds)
        // TODO: WOOMOB-1677 - For very large catalogs, consider hybrid approach: try immediate parse, defer if timeout.
        do {
            try await parseHandler(fileURL, state.siteID)
            DDLogInfo("✅ Background catalog processing completed successfully")
        } catch {
            DDLogError("⛔️ Failed to process catalog in background: \(error)")
        }

        // Clean up state
        BackgroundDownloadState.clear()
    }
}
