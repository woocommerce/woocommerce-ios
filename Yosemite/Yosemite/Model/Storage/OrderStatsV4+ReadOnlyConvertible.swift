import Foundation
import Storage


// MARK: - Storage.OrderStatsV4: ReadOnlyConvertible
//
extension Storage.OrderStatsV4: ReadOnlyConvertible {

    /// Updates the Storage.OrderStatsV4 with the ReadOnly.
    ///
    public func update(with stats: Yosemite.OrderStatsV4) {
        siteID = stats.siteID
        granularity = stats.granularity.rawValue
        totals?.update(with: stats.totals)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStatsV4 {
        let statsIntervals = intervals?.map { $0.toReadOnly()} ?? [Yosemite.OrderStatsV4Interval]()

        return OrderStatsV4(siteID: siteID,
                            granularity: StatsGranularityV4(rawValue: granularity) ?? .hourly,
                            totals: totals?.toReadOnly() ?? createReadOnlyTotals(),
                            intervals: statsIntervals)
    }

    // MARK: - Private Helpers
    //
    private func createReadOnlyTotals() -> Yosemite.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: 0,
                                  totalItemsSold: 0,
                                  grossRevenue: 0,
                                  couponDiscount: 0,
                                  totalCoupons: 0,
                                  refunds: 0,
                                  taxes: 0,
                                  shipping: 0,
                                  netRevenue: 0,
                                  totalProducts: 0,
                                  averageOrderValue: 0)
    }
}
