import Foundation
import Yosemite

/// View model for `StorePerformanceView`.
///
final class StorePerformanceViewModel: ObservableObject {
    @Published private(set) var timeRange = StatsTimeRangeV4.today

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }
}
