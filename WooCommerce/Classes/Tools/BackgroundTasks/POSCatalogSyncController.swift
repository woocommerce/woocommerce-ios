import Foundation

/// Provides easy access to POS catalog sync operations from anywhere in the app.
/// This class serves as a bridge between the UI and the background sync manager.
///
final class POSCatalogSyncController {
    
    /// Shared instance for app-wide access
    static let shared = POSCatalogSyncController()
    
    private init() {}
    
    /// Reference to the background sync manager from AppDelegate
    private var syncManager: POSCatalogSyncBackgroundTaskManager? {
        return AppDelegate.shared.posCatalogSyncManager
    }
    
    // MARK: - Public Interface
    
    /// Checks if a full catalog sync is currently in progress
    var isFullSyncInProgress: Bool {
        // This would check the sync state - implementation depends on exposing state from the manager
        return false // TODO: Implement by exposing state from POSCatalogSyncBackgroundTaskManager
    }
    
    /// Starts a foreground full catalog sync that continues in background
    /// Returns a task that can be used to monitor progress or cancellation
    @discardableResult
    func startForegroundFullSync() -> Task<Void, Error>? {
        guard let syncManager = syncManager else {
            DDLogError("⛔️ POS catalog sync manager not available")
            return nil
        }
        
        DDLogInfo("📱 Starting foreground POS catalog sync via controller...")
        return syncManager.startForegroundFullSync()
    }
    
    /// Manually triggers an incremental sync (typically not needed as it's scheduled automatically)
    func triggerIncrementalSync() {
        guard let syncManager = syncManager else {
            DDLogError("⛔️ POS catalog sync manager not available")
            return
        }
        
        syncManager.scheduleIncrementalSync()
        DDLogInfo("📱 Manually triggered incremental POS catalog sync")
    }
    
    /// Re-schedules background syncs (useful after user settings changes)
    func rescheduleBackgroundSyncs() {
        guard let syncManager = syncManager else {
            DDLogError("⛔️ POS catalog sync manager not available")
            return
        }
        
        syncManager.scheduleFullCatalogSync()
        syncManager.scheduleIncrementalSync()
        DDLogInfo("📱 Rescheduled POS catalog background syncs")
    }
}

// MARK: - Usage Example
/*
 
 // In a POS view controller when user first logs in:
 if POSCatalogSyncController.shared.isFullSyncInProgress == false {
     let syncTask = POSCatalogSyncController.shared.startForegroundFullSync()
     // Show progress UI and monitor syncTask as needed
 }
 
 // In settings when user changes sync preferences:
 POSCatalogSyncController.shared.rescheduleBackgroundSyncs()
 
 */