import Foundation
import Storage

public protocol POSCatalogSyncCoordinatorProtocol {
    /// Performs a full catalog sync for the specified site
    /// - Parameter siteID: The site ID to sync catalog for
    /// - Returns: The synced catalog containing products and variations
    func performFullSync(for siteID: Int64) async throws -> POSCatalog

    /// Determines if a full sync should be performed based on the age of the last sync
    /// - Parameters:
    ///   - siteID: The site ID to check
    ///   - maxAge: Maximum age before a sync is considered stale
    /// - Returns: True if a sync should be performed
    func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) -> Bool
}

public final class POSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    private let syncService: POSCatalogFullSyncServiceProtocol
    private let settingsStore: SiteSpecificAppSettingsStoreMethodsProtocol

    public init(syncService: POSCatalogFullSyncServiceProtocol,
                settingsStore: SiteSpecificAppSettingsStoreMethodsProtocol? = nil) {
        self.syncService = syncService
        self.settingsStore = settingsStore ?? SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage())
    }

    public func performFullSync(for siteID: Int64) async throws -> POSCatalog {
        DDLogInfo("🔄 POSCatalogSyncCoordinator starting full sync for site \(siteID)")

        let catalog = try await syncService.startFullSync(for: siteID)

        // Record the sync timestamp
        settingsStore.setPOSLastFullSyncDate(Date(), for: siteID)

        DDLogInfo("✅ POSCatalogSyncCoordinator completed full sync for site \(siteID)")
        return catalog
    }

    public func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) -> Bool {
        guard let lastSyncDate = lastFullSyncDate(for: siteID) else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: No previous sync found for site \(siteID), sync needed")
            return true
        }

        let age = Date().timeIntervalSince(lastSyncDate)
        let shouldSync = age > maxAge

        if shouldSync {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Last sync for site \(siteID) was \(Int(age))s ago (max: \(Int(maxAge))s), sync needed")
        } else {
            DDLogInfo("📋 POSCatalogSyncCoordinator: Last sync for site \(siteID) was \(Int(age))s ago (max: \(Int(maxAge))s), sync not needed")
        }

        return shouldSync
    }

    // MARK: - Private

    private func lastFullSyncDate(for siteID: Int64) -> Date? {
        return settingsStore.getPOSLastFullSyncDate(for: siteID)
    }
}
