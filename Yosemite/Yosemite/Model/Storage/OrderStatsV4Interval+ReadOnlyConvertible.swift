import Foundation
import Storage


// MARK: - Storage.OrderStatsV4Interval: ReadOnlyConvertible
//
extension Storage.OrderStatsV4Interval: ReadOnlyConvertible {

    /// Updates the StorageOrderStatsV4Interval with the ReadOnly.
    ///
    public func update(with statsInterval: Yosemite.OrderStatsV4Interval) {
        interval = statsInterval.interval
        dateStart = statsInterval.dateStart
        dateEnd = statsInterval.dateEnd
        subtotals?.update(with: statsInterval.subtotals)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStatsV4Interval {
        return OrderStatsV4Interval(interval: interval ?? "",
                                    dateStart: dateStart ?? "",
                                    dateEnd: dateEnd ?? "",
                                    subtotals: subtotals?.toReadOnly() ?? createReadOnlySubTotals())
    }

    // MARK: - Private Helpers
    //
    private func createReadOnlySubTotals() -> Yosemite.OrderStatsV4Totals {
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
