import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `GoogleAdsDashboardCard`.
final class GoogleAdsDashboardCardViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    @Published private(set) var syncingError: Error?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
    }
}
