import Foundation
import BackgroundTasks
import Yosemite
import UIKit

/// Manages POS catalog background synchronization tasks.
/// Handles both full catalog downloads (BGProcessingTask) and incremental syncs (BGAppRefreshTask).
///
final class POSCatalogSyncBackgroundTaskManager {

    // MARK: - Task Identifiers

    /// Full catalog download using BGProcessingTask - for large downloads that can wait for optimal conditions
    static let fullCatalogSyncIdentifier = "com.automattic.woocommerce.pos.fullCatalogSync"

    /// Incremental sync using BGAppRefreshTask - for quick updates when app is backgrounded
    static let incrementalSyncIdentifier = "com.automattic.woocommerce.pos.incrementalSync"

    // MARK: - Dependencies

    private let stores: StoresManager
    private let urlSession: URLSession

    // MARK: - State Management

    /// State of ongoing sync operations - persisted to handle app lifecycle changes
    private var syncState: POSSyncState {
        get {
            if let data = UserDefaults.standard.data(forKey: "pos_sync_state"),
               let state = try? JSONDecoder().decode(POSSyncState.self, from: data) {
                return state
            }
            return POSSyncState()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "pos_sync_state")
            }
        }
    }

    // MARK: - Initialization

    init(stores: StoresManager = ServiceLocator.stores, urlSession: URLSession? = nil) {
        self.stores = stores

        // Create background URLSession configuration for reliable downloads
        let config = URLSessionConfiguration.background(withIdentifier: "com.automattic.woocommerce.pos.backgroundSync")
        config.isDiscretionary = true  // System can delay for optimal conditions
        config.allowsCellularAccess = false  // WiFi only for large downloads
        config.sessionSendsLaunchEvents = true  // Wake app when download completes

        self.urlSession = urlSession ?? URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }

    // MARK: - Registration

    /// Registers all POS catalog sync tasks with the system
    func registerBackgroundTasks() {
        // Only register if not running tests
        guard !Self.isRunningTests() else { return }

        DDLogInfo("📱 Registering POS catalog background tasks...")

        // Register full catalog sync (BGProcessingTask)
        let fullSyncRegistered = BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.fullCatalogSyncIdentifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                DDLogError("⛔️ Failed to cast to BGProcessingTask for full catalog sync")
                task.setTaskCompleted(success: false)
                return
            }
            self.handleFullCatalogSync(task: processingTask)
        }
        DDLogInfo("📱 Full catalog sync registration: \(fullSyncRegistered ? "✅ Success" : "❌ Failed")")

        // Register incremental sync (BGAppRefreshTask)  
        let incrementalSyncRegistered = BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.incrementalSyncIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                DDLogError("⛔️ Failed to cast to BGAppRefreshTask for incremental sync")
                task.setTaskCompleted(success: false)
                return
            }
            self.handleIncrementalSync(task: refreshTask)
        }
        DDLogInfo("📱 Incremental sync registration: \(incrementalSyncRegistered ? "✅ Success" : "❌ Failed")")

        DDLogInfo("📱 Successfully registered POS catalog background tasks")
    }

    // MARK: - Scheduling

    /// Schedules a full catalog sync (BGProcessingTask)
    /// Should be called weekly or daily, when device is idle with WiFi
    func scheduleFullCatalogSync() {
        guard !Self.isRunningTests() else { 
            DDLogInfo("📱 Skipping full sync scheduling - running tests")
            return 
        }

        DDLogInfo("📱 Attempting to schedule full catalog sync...")
        
        // Cancel any existing request first
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.fullCatalogSyncIdentifier)
        DDLogInfo("📱 Cancelled existing full sync task if any")

        let request = BGProcessingTaskRequest(identifier: Self.fullCatalogSyncIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false  // Can run on battery but system will prefer charging
        request.earliestBeginDate = Date(timeIntervalSinceNow: 20 * 60) // No earlier than 20 minutes
        
        DDLogInfo("📱 Full sync request created:")
        DDLogInfo("📱   ID: \(request.identifier)")
        DDLogInfo("📱   Earliest: \(request.earliestBeginDate?.description ?? "immediately")")
        DDLogInfo("📱   Requires network: \(request.requiresNetworkConnectivity)")
        DDLogInfo("📱   Requires power: \(request.requiresExternalPower)")
        DDLogInfo("📱   Current time: \(Date().description)")
        
        // Let's also try with less restrictive requirements for testing
        if Self.isRunningDebugBuild() {
            DDLogInfo("📱 🧪 Using relaxed requirements for debug testing")
            request.requiresExternalPower = false
            request.requiresNetworkConnectivity = false  // Try without network requirement
            request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60) // Shorter delay for testing
            DDLogInfo("📱 🧪 Debug config: network=false, power=false, delay=2min")
        }

        do {
            try BGTaskScheduler.shared.submit(request)
            DDLogInfo("📱 ✅ Successfully submitted full POS catalog sync")
            DDLogInfo("📱 Full sync task config: network=\(request.requiresNetworkConnectivity), power=\(request.requiresExternalPower)")
            
            // Verify it was actually queued by checking immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                BGTaskScheduler.shared.getPendingTaskRequests { taskRequests in
                    let ourTask = taskRequests.first { $0.identifier == Self.fullCatalogSyncIdentifier }
                    DDLogInfo("📱 Full sync task verification: \(ourTask != nil ? "✅ Found in pending queue" : "❌ NOT found in pending queue")")
                }
            }
            
            ServiceLocator.analytics.track(event: .POSCatalogSync.fullSyncScheduled())
        } catch {
            DDLogError("⛔️ Failed to schedule full POS catalog sync: \(error)")
            DDLogError("⛔️ Error type: \(type(of: error)), localizedDescription: \(error.localizedDescription)")
            if let bgError = error as? BGTaskScheduler.Error {
                DDLogError("⛔️ BGTaskScheduler error code: \(bgError.code)")
            }
            ServiceLocator.analytics.track(event: .POSCatalogSync.schedulingError(error, taskType: "full"))
        }
    }

    /// Schedules an incremental sync (BGAppRefreshTask)
    /// Should be called more frequently for quick updates
    func scheduleIncrementalSync() {
        guard !Self.isRunningTests() else { 
            DDLogInfo("📱 Skipping incremental sync scheduling - running tests")
            return 
        }

        DDLogInfo("📱 Attempting to schedule incremental sync...")
        
        // Cancel any existing request first
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.incrementalSyncIdentifier)
        DDLogInfo("📱 Cancelled existing incremental sync task if any")

        let request = BGAppRefreshTaskRequest(identifier: Self.incrementalSyncIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // No earlier than 5 minutes
        
        DDLogInfo("📱 Incremental sync request created: ID=\(request.identifier), earliest=\(request.earliestBeginDate?.description ?? "now")")

        do {
            try BGTaskScheduler.shared.submit(request)
            DDLogInfo("📱 ✅ Successfully submitted incremental POS catalog sync")
            
            // Verify it was actually queued by checking immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                BGTaskScheduler.shared.getPendingTaskRequests { taskRequests in
                    let ourTask = taskRequests.first { $0.identifier == Self.incrementalSyncIdentifier }
                    DDLogInfo("📱 Incremental sync task verification: \(ourTask != nil ? "✅ Found in pending queue" : "❌ NOT found in pending queue")")
                }
            }
            
            ServiceLocator.analytics.track(event: .POSCatalogSync.incrementalSyncScheduled())
        } catch {
            DDLogError("⛔️ Failed to schedule incremental POS catalog sync: \(error)")
            DDLogError("⛔️ Error type: \(type(of: error)), localizedDescription: \(error.localizedDescription)")
            if let bgError = error as? BGTaskScheduler.Error {
                DDLogError("⛔️ BGTaskScheduler error code: \(bgError.code)")
            }
            ServiceLocator.analytics.track(event: .POSCatalogSync.schedulingError(error, taskType: "incremental"))
        }
    }

    // MARK: - Foreground Sync Support

    /// Starts a full catalog sync in the foreground that will continue in background
    /// Returns a task that can be monitored for progress
    func startForegroundFullSync() -> Task<Void, Error> {
        DDLogInfo("📱 Starting foreground POS catalog sync that will continue in background...")

        return Task {
            var currentSyncState = self.syncState
            currentSyncState.isFullSyncInProgress = true
            currentSyncState.lastFullSyncStartTime = Date()
            self.syncState = currentSyncState

            do {
                try await self.performFullCatalogSync()

                // Update successful completion state
                var completedState = self.syncState
                completedState.isFullSyncInProgress = false
                completedState.lastFullSyncCompletionTime = Date()
                self.syncState = completedState

                DDLogInfo("📱 Foreground full POS catalog sync completed successfully")
                ServiceLocator.analytics.track(event: .POSCatalogSync.fullSyncCompleted(source: "foreground"))

            } catch {
                // Update error state but keep sync as in progress for potential resume
                var errorState = self.syncState
                errorState.lastFullSyncError = error.localizedDescription
                self.syncState = errorState

                DDLogError("⛔️ Foreground full POS catalog sync failed: \(error)")
                ServiceLocator.analytics.track(event: .POSCatalogSync.fullSyncError(error, source: "foreground"))
                throw error
            }
        }
    }

    // MARK: - App Launch Recovery

    /// Should be called on app launch to recover from incomplete syncs
    func recoverIncompletesyncs() {
        let currentState = syncState

        // Check for incomplete full sync that needs processing
        if currentState.isFullSyncInProgress,
           let downloadPath = currentState.pendingFullCatalogPath,
           FileManager.default.fileExists(atPath: downloadPath) {

            DDLogInfo("📱 Recovering incomplete POS catalog sync from app launch")

            Task {
                do {
                    try await self.processDownloadedCatalog(at: URL(fileURLWithPath: downloadPath))

                    // Update completion state
                    var recoveredState = self.syncState
                    recoveredState.isFullSyncInProgress = false
                    recoveredState.pendingFullCatalogPath = nil
                    recoveredState.lastFullSyncCompletionTime = Date()
                    self.syncState = recoveredState

                    DDLogInfo("📱 Successfully recovered incomplete POS catalog sync")
                    ServiceLocator.analytics.track(event: .POSCatalogSync.syncRecovered())

                } catch {
                    DDLogError("⛔️ Failed to recover incomplete POS catalog sync: \(error)")
                    ServiceLocator.analytics.track(event: .POSCatalogSync.recoveryError(error))
                }
            }
        }
    }
}

// MARK: - Background Task Handlers

private extension POSCatalogSyncBackgroundTaskManager {

    /// Handles full catalog sync using BGProcessingTask
    func handleFullCatalogSync(task: BGProcessingTask) {
        DDLogInfo("📱 Starting full POS catalog sync in background...")

        // Schedule next full sync - do this after task completion to avoid conflicts
        defer { scheduleFullCatalogSync() }

        let syncTask = Task {
            do {
                let startTime = Date()
                try await self.performFullCatalogSync()

                let duration = Date().timeIntervalSince(startTime)
                DDLogInfo("📱 Full POS catalog sync completed in \(duration) seconds")
                ServiceLocator.analytics.track(event: .POSCatalogSync.fullSyncCompleted(source: "background", duration: duration))

                task.setTaskCompleted(success: true)

            } catch {
                DDLogError("⛔️ Full POS catalog sync failed: \(error)")
                ServiceLocator.analytics.track(event: .POSCatalogSync.fullSyncError(error, source: "background"))
                task.setTaskCompleted(success: false)
            }
        }

        // Handle task expiration
        task.expirationHandler = {
            DDLogInfo("📱 Full POS catalog sync task expired, cancelling...")
            ServiceLocator.analytics.track(event: .POSCatalogSync.taskExpired(taskType: "full"))
            syncTask.cancel()
        }
    }

    /// Handles incremental sync using BGAppRefreshTask
    func handleIncrementalSync(task: BGAppRefreshTask) {
        DDLogInfo("📱 Starting incremental POS catalog sync in background...")

        // Schedule next incremental sync - do this after task completion to avoid conflicts
        defer { scheduleIncrementalSync() }

        let syncTask = Task {
            do {
                let startTime = Date()
                try await self.performIncrementalSync()

                let duration = Date().timeIntervalSince(startTime)
                DDLogInfo("📱 Incremental POS catalog sync completed in \(duration) seconds")
                ServiceLocator.analytics.track(event: .POSCatalogSync.incrementalSyncCompleted(duration: duration))

                task.setTaskCompleted(success: true)

            } catch {
                DDLogError("⛔️ Incremental POS catalog sync failed: \(error)")
                ServiceLocator.analytics.track(event: .POSCatalogSync.incrementalSyncError(error))
                task.setTaskCompleted(success: false)
            }
        }

        // Handle task expiration
        task.expirationHandler = {
            DDLogInfo("📱 Incremental POS catalog sync task expired, cancelling...")
            ServiceLocator.analytics.track(event: .POSCatalogSync.taskExpired(taskType: "incremental"))
            syncTask.cancel()
        }
    }
}

// MARK: - Sync Implementation Stubs

private extension POSCatalogSyncBackgroundTaskManager {

    /// Performs the full catalog download and processing
    /// Downloads the 80MB JSON catalog from staging site
    func performFullCatalogSync() async throws {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            throw POSCatalogSyncError.noActiveSite
        }

        let startTime = Date()
        DDLogInfo("📱 [FULL-SYNC] Starting full catalog download for siteID: \(siteID)")
        DDLogInfo("📱 [FULL-SYNC] Available background execution time at start: \(formatBackgroundTime(UIApplication.shared.backgroundTimeRemaining))")

        // Update state to indicate download in progress
        var currentState = syncState
        currentState.isFullSyncInProgress = true
        currentState.lastFullSyncStartTime = Date()
        syncState = currentState

        do {
            // Step 1: Download the 80MB JSON file
            let downloadStartTime = Date()
            let catalogURL = URL(string: "https://poslarge.mystagingwebsite.com/wp-content/uploads/pos-catalog.json")!

            DDLogInfo("📱 [FULL-SYNC] Starting download from: \(catalogURL.absoluteString)")

            let (data, response) = try await URLSession.shared.data(from: catalogURL)
            let downloadDuration = Date().timeIntervalSince(downloadStartTime)
            let fileSizeMB = Double(data.count) / (1024 * 1024)

            DDLogInfo("📱 [FULL-SYNC] Downloaded \(String(format: "%.1f", fileSizeMB))MB in \(String(format: "%.2f", downloadDuration)) seconds")
            DDLogInfo("📱 [FULL-SYNC] Background time remaining after download: \(formatBackgroundTime(UIApplication.shared.backgroundTimeRemaining))")

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw POSCatalogSyncError.downloadFailed(URLError(.badServerResponse))
            }

            // Step 2: Parse JSON - simulate realistic parsing time
            let parseStartTime = Date()
            DDLogInfo("📱 [FULL-SYNC] Starting JSON parsing...")

            // On older hardware, parsing 80MB JSON could take 10-20 seconds
            // We'll simulate this since we don't actually need the parsed data yet
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                let parseDuration = Date().timeIntervalSince(parseStartTime)
                DDLogInfo("📱 [FULL-SYNC] JSON parsed in \(String(format: "%.2f", parseDuration)) seconds")
                DDLogInfo("📱 [FULL-SYNC] Background time remaining after parsing: \(formatBackgroundTime(UIApplication.shared.backgroundTimeRemaining))")

                // Simulate realistic processing time
                try await simulateDatabaseInsertion()

            } catch {
                DDLogError("⛔️ JSON parsing failed: \(error)")
                throw POSCatalogSyncError.processingFailed(error)
            }

            // Step 3: Update completion state
            var completedState = syncState
            completedState.isFullSyncInProgress = false
            completedState.lastFullSyncCompletionTime = Date()
            completedState.pendingFullCatalogPath = nil
            syncState = completedState

            let totalDuration = Date().timeIntervalSince(startTime)
            DDLogInfo("📱 [FULL-SYNC] Full catalog sync completed in \(String(format: "%.2f", totalDuration)) seconds")
            DDLogInfo("📱 [FULL-SYNC] Background time remaining at completion: \(formatBackgroundTime(UIApplication.shared.backgroundTimeRemaining))")

        } catch {
            DDLogError("⛔️ Full catalog sync failed: \(error)")

            // Update error state
            var errorState = syncState
            errorState.lastFullSyncError = error.localizedDescription
            syncState = errorState

            throw error
        }
    }

    /// Simulates realistic database insertion time for older hardware
    /// Real implementation would insert parsed catalog data into Core Data
    private func simulateDatabaseInsertion() async throws {
        let insertStartTime = Date()
        DDLogInfo("📱 [FULL-SYNC] Starting database insertion simulation...")

        // Simulate inserting thousands of products/variations/coupons
        // On older hardware with thousands of items, this could take 20-40 seconds
        // We'll simulate a shorter time to see what actually gets done
        for batch in 1...10 {
            // Each batch represents processing ~1000 items
            let batchStartTime = Date()

            // Check if we still have background time
            let remainingTime = UIApplication.shared.backgroundTimeRemaining
            DDLogInfo("📱 [FULL-SYNC] Processing batch \(batch)/10, background time remaining: \(formatBackgroundTime(remainingTime))")

            if remainingTime < 5.0 {
                DDLogWarn("⚠️ Background time running low, may not complete all processing")
            }

            // Simulate processing time per batch (2-4 seconds per 1000 items on older hardware)
            try await Task.sleep(for: .seconds(2.5))

            let batchDuration = Date().timeIntervalSince(batchStartTime)
            DDLogInfo("📱 [FULL-SYNC] Batch \(batch) completed in \(String(format: "%.2f", batchDuration)) seconds")

            // Stop if we're running out of time
            if UIApplication.shared.backgroundTimeRemaining < 3.0 {
                DDLogWarn("⚠️ Stopping processing due to low background time remaining")
                break
            }
        }

        let totalInsertDuration = Date().timeIntervalSince(insertStartTime)
        DDLogInfo("📱 [FULL-SYNC] Database insertion simulation completed in \(String(format: "%.2f", totalInsertDuration)) seconds")
    }

    /// Performs incremental sync using PointOfSaleItemService
    /// Fetches a few pages of products to update recent changes
    func performIncrementalSync() async throws {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            throw POSCatalogSyncError.noActiveSite
        }

        let startTime = Date()
        let lastSync = UserDefaults.standard[.lastPOSIncrementalSyncTimestamp] as? Date ?? Date.distantPast

        DDLogInfo("📱 [INCREMENTAL-SYNC] Starting incremental sync for siteID: \(siteID), last sync: \(lastSync)")
        DDLogInfo("📱 [INCREMENTAL-SYNC] Available background execution time at start: \(formatBackgroundTime(UIApplication.shared.backgroundTimeRemaining))")

        do {
            // Create POS item service for fetching products
            let currencySettings = ServiceLocator.currencySettings
            let itemService = PointOfSaleItemService(currencySettings: currencySettings)

            // Create fetch strategy factory and then get the default strategy
            let strategyFactory = PointOfSaleItemFetchStrategyFactory(
                siteID: siteID,
                credentials: stores.sessionManager.defaultCredentials
            )
            let analytics = POSItemFetchAnalytics(itemType: .product)
            let fetchStrategy = strategyFactory.defaultStrategy(analytics: analytics)

            var totalItemsFetched = 0
            let maxPages = 3 // Limit to 3 pages for incremental sync to stay within background time limits

            // Fetch a few pages of products to get recent updates
            for pageNumber in 1...maxPages {
                let pageStartTime = Date()
                let remainingTime = UIApplication.shared.backgroundTimeRemaining

                DDLogInfo("📱 [INCREMENTAL-SYNC] Fetching page \(pageNumber)/\(maxPages), background time remaining: \(formatBackgroundTime(remainingTime))")

                if remainingTime < 10.0 {
                    DDLogWarn("⚠️ [INCREMENTAL-SYNC] Background time running low, stopping incremental sync at page \(pageNumber)")
                    break
                }

                do {
                    let pagedItems = try await itemService.providePointOfSaleItems(
                        pageNumber: pageNumber,
                        fetchStrategy: fetchStrategy
                    )

                    let pageDuration = Date().timeIntervalSince(pageStartTime)
                    totalItemsFetched += pagedItems.items.count

                    DDLogInfo("📱 [INCREMENTAL-SYNC] Page \(pageNumber): fetched \(pagedItems.items.count) items in \(String(format: "%.2f", pageDuration)) seconds")
                    DDLogInfo("📱 [INCREMENTAL-SYNC] Background time remaining after page \(pageNumber): \(formatBackgroundTime(UIApplication.shared.backgroundTimeRemaining))")

                    // Simulate database update time (would normally update Core Data here)
                    if !pagedItems.items.isEmpty {
                        try await simulateIncrementalDatabaseUpdate(itemCount: pagedItems.items.count)
                    }

                    // Stop if no more pages
                    if !pagedItems.hasMorePages {
                        DDLogInfo("📱 [INCREMENTAL-SYNC] Reached end of available pages at page \(pageNumber)")
                        break
                    }

                } catch {
                    DDLogError("⛔️ Failed to fetch page \(pageNumber): \(error)")
                    // Continue with next page rather than failing completely
                }
            }

            // Update last sync timestamp
            UserDefaults.standard[.lastPOSIncrementalSyncTimestamp] = Date()

            let totalDuration = Date().timeIntervalSince(startTime)
            DDLogInfo("📱 [INCREMENTAL-SYNC] Incremental sync completed: \(totalItemsFetched) items in \(String(format: "%.2f", totalDuration)) seconds")
            DDLogInfo("📱 [INCREMENTAL-SYNC] Background time remaining at completion: \(formatBackgroundTime(UIApplication.shared.backgroundTimeRemaining))")

        } catch {
            DDLogError("⛔️ Incremental sync failed: \(error)")
            throw error
        }
    }

    /// Simulates database update time for incremental sync
    /// Real implementation would update existing records or insert new ones
    private func simulateIncrementalDatabaseUpdate(itemCount: Int) async throws {
        let updateStartTime = Date()

        // Simulate time to update database records (much faster than full insert)
        // Estimate 0.1 seconds per 100 items for incremental updates
        let estimatedSeconds = Double(itemCount) / 1000.0
        let actualSeconds = max(0.1, min(estimatedSeconds, 2.0)) // Between 0.1 and 2 seconds

        try await Task.sleep(for: .seconds(actualSeconds))

        let updateDuration = Date().timeIntervalSince(updateStartTime)
        DDLogInfo("📱 [INCREMENTAL-SYNC] Updated \(itemCount) items in database in \(String(format: "%.2f", updateDuration)) seconds")
    }

    /// Processes a downloaded catalog file (for recovery scenarios)
    func processDownloadedCatalog(at url: URL) async throws {
        DDLogInfo("📱 Processing downloaded catalog at: \(url.path)")

        // TODO: Implement catalog processing
        // This would:
        // 1. Decompress the JSON file
        // 2. Parse catalog data
        // 3. Insert/update database records
        // 4. Clean up temporary file

        throw POSCatalogSyncError.notImplemented("Catalog processing implementation needed")
    }
}

// MARK: - State Management

/// Represents the current state of POS catalog synchronization
private struct POSSyncState: Codable {
    var isFullSyncInProgress: Bool = false
    var lastFullSyncStartTime: Date?
    var lastFullSyncCompletionTime: Date?
    var lastFullSyncError: String?
    var pendingFullCatalogPath: String? // Path to downloaded but unprocessed catalog

    var lastIncrementalSyncTime: Date?
    var lastIncrementalSyncError: String?
}

// MARK: - Error Types

enum POSCatalogSyncError: LocalizedError {
    case noActiveSite
    case notImplemented(String)
    case downloadFailed(Error)
    case processingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noActiveSite:
            return "No active site available for sync"
        case .notImplemented(let message):
            return message
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .processingFailed(let error):
            return "Processing failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Helper Extensions

private extension POSCatalogSyncBackgroundTaskManager {
    static func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
    
    static func isRunningDebugBuild() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Formats background time remaining for logging, avoiding huge numbers in foreground
    func formatBackgroundTime(_ time: TimeInterval) -> String {
        return time < Double.greatestFiniteMagnitude ? "\(String(format: "%.1f", time)) seconds" : "unlimited (foreground)"
    }
}
