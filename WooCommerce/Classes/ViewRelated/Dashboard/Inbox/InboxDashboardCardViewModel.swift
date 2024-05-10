import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `InboxDashboardCard`.
///
final class InboxDashboardCardViewModel: ObservableObject {
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?

    private let siteID: Int64
    private let stores: StoresManager
    private let storage: StorageManagerType
    private let analytics: Analytics
    
    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.storage = storage
        self.analytics = analytics
    }

    func dismissInbox() {
        // TODO
    }
}
