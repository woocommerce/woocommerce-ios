import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `ProductStockDashboardCard`
///
final class ProductStockDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?

    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores
        self.storageManager = storageManager
    }

    @MainActor
    func reloadData() async {
        // TODO
    }

    func dismissStock() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .stock))
        onDismiss?()
    }
}
