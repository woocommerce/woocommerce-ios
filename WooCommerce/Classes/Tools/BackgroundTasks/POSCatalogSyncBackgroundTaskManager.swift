import Foundation
import BackgroundTasks
import Yosemite

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
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.fullCatalogSyncIdentifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                DDLogError("⛔️ Failed to cast to BGProcessingTask for full catalog sync")
                task.setTaskCompleted(success: false)
                return
            }
            self.handleFullCatalogSync(task: processingTask)
        }
        
        // Register incremental sync (BGAppRefreshTask)  
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.incrementalSyncIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                DDLogError("⛔️ Failed to cast to BGAppRefreshTask for incremental sync")
                task.setTaskCompleted(success: false)
                return
            }
            self.handleIncrementalSync(task: refreshTask)
        }
        
        DDLogInfo("📱 Successfully registered POS catalog background tasks")
    }
    
    // MARK: - Scheduling
    
    /// Schedules a full catalog sync (BGProcessingTask)
    /// Should be called weekly or daily, when device is idle with WiFi
    func scheduleFullCatalogSync() {
        guard !Self.isRunningTests() else { return }
        
        let request = BGProcessingTaskRequest(identifier: Self.fullCatalogSyncIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false  // Can run on battery but system will prefer charging
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // No earlier than 1 day
        
        do {
            try BGTaskScheduler.shared.submit(request)
            DDLogInfo("📱 Scheduled full POS catalog sync for: \(request.earliestBeginDate?.description ?? "unknown")")
            ServiceLocator.analytics.track(event: .POSCatalogSync.fullSyncScheduled())
        } catch {
            DDLogError("⛔️ Failed to schedule full POS catalog sync: \(error)")
            ServiceLocator.analytics.track(event: .POSCatalogSync.schedulingError(error, taskType: "full"))
        }
    }
    
    /// Schedules an incremental sync (BGAppRefreshTask)
    /// Should be called more frequently for quick updates
    func scheduleIncrementalSync() {
        guard !Self.isRunningTests() else { return }
        
        let request = BGAppRefreshTaskRequest(identifier: Self.incrementalSyncIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60) // No earlier than 4 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
            DDLogInfo("📱 Scheduled incremental POS catalog sync for: \(request.earliestBeginDate?.description ?? "unknown")")
            ServiceLocator.analytics.track(event: .POSCatalogSync.incrementalSyncScheduled())
        } catch {
            DDLogError("⛔️ Failed to schedule incremental POS catalog sync: \(error)")
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
        
        // Schedule next full sync
        scheduleFullCatalogSync()
        
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
        
        // Schedule next incremental sync
        scheduleIncrementalSync()
        
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
    /// This would download the <100MB compressed JSON file
    func performFullCatalogSync() async throws {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            throw POSCatalogSyncError.noActiveSite
        }
        
        DDLogInfo("📱 Starting full catalog download for siteID: \(siteID)")
        
        // Update state to indicate download in progress
        var currentState = syncState
        currentState.isFullSyncInProgress = true
        currentState.lastFullSyncStartTime = Date()
        syncState = currentState
        
        // TODO: Implement actual full catalog download
        // This would:
        // 1. Create background URLSession download task
        // 2. Download compressed JSON catalog
        // 3. Store file path in syncState.pendingFullCatalogPath
        // 4. Process and insert into database
        // 5. Update syncState completion
        
        throw POSCatalogSyncError.notImplemented("Full catalog sync implementation needed")
    }
    
    /// Performs incremental sync using REST API endpoints
    /// This would fetch only changed products/variations/coupons using timestamp
    func performIncrementalSync() async throws {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            throw POSCatalogSyncError.noActiveSite
        }
        
        let lastSync = UserDefaults.standard[.lastPOSIncrementalSyncTimestamp] as? Date ?? Date.distantPast
        DDLogInfo("📱 Starting incremental sync for siteID: \(siteID), last sync: \(lastSync)")
        
        // TODO: Implement actual incremental sync
        // This would:
        // 1. Fetch products modified since lastSync timestamp
        // 2. Fetch variations modified since lastSync timestamp  
        // 3. Fetch coupons modified since lastSync timestamp
        // 4. Update local database
        // 5. Update lastPOSIncrementalSyncTimestamp
        
        throw POSCatalogSyncError.notImplemented("Incremental sync implementation needed")
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
}

// MARK: - UserDefaults Keys Extension

private extension UserDefaults.Key {
    static let lastPOSIncrementalSyncTimestamp = UserDefaults.Key("lastPOSIncrementalSyncTimestamp")
}