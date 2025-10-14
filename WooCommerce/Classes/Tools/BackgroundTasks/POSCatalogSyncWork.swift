import Foundation
import Yosemite

struct POSCatalogSyncWork: BackgroundWork {
    let identifier = "com.automattic.woocommerce.refresh.pos.catalog.sync"
    let period: TimeInterval = 60 * 60 // 60 minutes
    let executionContext: WorkExecutionContext = .both
    private let twentyFourHours: TimeInterval = 24 * 60 * 60

    func execute() async throws {
//        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
//            DDLogWarn("[BackgroundWork] No default store ID, skipping sync")
//            return
//        }
//
//        guard let coordinator = ServiceLocator.stores.posCatalogSyncCoordinator else {
//            DDLogError("[BackgroundWork] POSCatalogSyncCoordinator not available")
//            throw POSCatalogSyncWorkError.coordinatorNotAvailable
//        }
//
//        let lastFullSyncDate = await coordinator.getLastFullSyncDate(for: siteID)
//
//        let shouldDoFullSync: Bool
//        if let lastFullSync = lastFullSyncDate {
//            let timeSinceFullSync = Date().timeIntervalSince(lastFullSync)
//            shouldDoFullSync = timeSinceFullSync >= twentyFourHours
//
//            if shouldDoFullSync {
//                DDLogInfo("[BackgroundWork] Last full sync was \(Int(timeSinceFullSync/3600))h ago (>24h), performing full sync")
//            } else {
//                DDLogInfo("[BackgroundWork] Last full sync was \(Int(timeSinceFullSync/3600))h ago (<24h), performing incremental sync")
//            }
//        } else {
//            shouldDoFullSync = true
//            DDLogInfo("[BackgroundWork] No previous full sync found, performing full sync")
//        }
//
//        if shouldDoFullSync {
//            try await coordinator.performFullSync(for: siteID)
//        } else {
//            try await coordinator.performIncrementalSync(for: siteID)
//        }
    }
}

enum POSCatalogSyncWorkError: Error {
    case coordinatorNotAvailable
}
