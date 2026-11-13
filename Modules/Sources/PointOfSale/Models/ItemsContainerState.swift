import Foundation
import enum Yosemite.POSCatalogSyncProgress

struct POSCatalogSyncViewState: Equatable {
    let progress: POSCatalogSyncProgress?

    init(progress: POSCatalogSyncProgress? = nil) {
        self.progress = progress
    }
}

enum ItemsContainerState {
    case loading(catalogSyncState: POSCatalogSyncViewState? = nil)
    case error(PointOfSaleErrorState)
    case content

    var isCatalogSyncing: Bool {
        catalogSyncState != nil
    }

    var catalogSyncState: POSCatalogSyncViewState? {
        switch self {
        case .loading(let catalogSyncState):
            return catalogSyncState
        default:
            return nil
        }
    }
}

extension ItemsContainerState: Equatable {}
