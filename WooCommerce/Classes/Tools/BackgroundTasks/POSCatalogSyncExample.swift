//
//  POSCatalogSyncExample.swift
//  WooCommerce
//
//  Example code showing how to use the POS Catalog Sync system
//  This file demonstrates the features and can be used for testing
//

import Foundation
import UIKit

// MARK: - Usage Examples

/*

 ## Testing the Background Sync System

 To test the background sync functionality:

 1. **Full Catalog Sync (BGProcessingTask)**
 - Will attempt to download 80MB JSON from https://poslarge.mystagingwebsite.com/wp-content/uploads/pos-catalog.json
 - Logs available background execution time at each step
 - Simulates realistic database processing times
 - Demonstrates how much can be completed within background time limits

 2. **Incremental Sync (BGAppRefreshTask)**
 - Uses PointOfSaleItemService to fetch a few pages of products
 - Shows timing for API calls vs database updates
 - Stops early if background time is running low

 ## Key Logging to Watch For:

 ```
 📱 Available background execution time at start: X.X seconds
 📱 Downloaded 80.0MB in 12.34 seconds
 📱 Background time remaining after download: X.X seconds
 📱 JSON parsed in 5.67 seconds
 📱 Background time remaining after parsing: X.X seconds
 📱 Processing batch 3/10, background time remaining: 8.9 seconds
 ⚠️ Background time running low, may not complete all processing
 📱 Full catalog sync completed in 45.67 seconds
 📱 Background time remaining at completion: 1.2 seconds
 ```

 ## Expected Results:

 - **BGProcessingTask**: Should get ~30-60 seconds typically, may complete 3-5 processing batches
 - **BGAppRefreshTask**: Should get ~15-30 seconds, may complete 1-3 pages of incremental sync
 - Both will log exactly how much time they receive and use

 ## Manual Testing:

 To manually test background sync behavior:

 ```swift
 // Test foreground sync that continues in background
 let syncTask = POSCatalogSyncController.shared.startForegroundFullSync()

 // Monitor the task and check logs for timing information
 Task {
 do {
 try await syncTask?.value
 print("✅ Sync completed successfully")
 } catch {
 print("❌ Sync failed: \(error)")
 }
 }

 // Test scheduling
 let syncManager = AppDelegate.shared.posCatalogSyncManager
 syncManager.scheduleFullCatalogSync()
 syncManager.scheduleIncrementalSync()
 ```

 ## Background Task Debugging:

 In Xcode, you can simulate background task execution:
 1. Set breakpoints in handleFullCatalogSync() or handleIncrementalSync()
 2. Run app in simulator
 3. Debug -> Simulate Background App Refresh
 4. Or use: e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.automattic.woocommerce.pos.fullCatalogSync"]

 This helps verify the background tasks are properly registered and can be invoked.

 */

// MARK: - Development Helper

#if DEBUG
struct POSCatalogSyncDevelopmentHelper {

    /// Logs the current background sync state for debugging
    static func logCurrentSyncState() {
        // This could access the sync state if we exposed it
        DDLogInfo("🔧 [DEV] Current POS sync state check requested")

        // Log last sync times from UserDefaults
        let lastIncremental = UserDefaults.standard.object(forKey: "lastPOSIncrementalSyncTimestamp") as? Date
        DDLogInfo("🔧 [DEV] Last incremental sync: \(lastIncremental?.description ?? "never")")

        // Log background refresh status
        let refreshStatus = UIApplication.shared.backgroundRefreshStatus
        switch refreshStatus {
        case .available:
            DDLogInfo("🔧 [DEV] Background App Refresh: Available ✅")
        case .denied:
            DDLogInfo("🔧 [DEV] Background App Refresh: Denied ❌")
        case .restricted:
            DDLogInfo("🔧 [DEV] Background App Refresh: Restricted ⚠️")
        @unknown default:
            DDLogInfo("🔧 [DEV] Background App Refresh: Unknown")
        }

        // Log remaining background time (only meaningful during background execution)
        let remainingTime = UIApplication.shared.backgroundTimeRemaining
        if remainingTime < Double.greatestFiniteMagnitude {
            DDLogInfo("🔧 [DEV] Background time remaining: \(String(format: "%.1f", remainingTime)) seconds")
        } else {
            DDLogInfo("🔧 [DEV] App is running in foreground")
        }
    }

    /// Manually triggers sync operations for testing
    static func triggerManualSync() {
        DDLogInfo("🔧 [DEV] Manually triggering POS catalog sync...")

        let controller = POSCatalogSyncController.shared

        // Start a foreground sync for immediate testing
        let syncTask = controller.startForegroundFullSync()

        Task {
            do {
                try await syncTask?.value
                DDLogInfo("🔧 [DEV] Manual sync completed successfully")
            } catch {
                DDLogError("🔧 [DEV] Manual sync failed: \(error)")
            }
        }
    }

    /// Schedules fresh background tasks for testing
    static func rescheduleBackgroundTasks() {
        DDLogInfo("🔧 [DEV] Rescheduling background tasks...")
        POSCatalogSyncController.shared.rescheduleBackgroundSyncs()
    }
}
#endif
