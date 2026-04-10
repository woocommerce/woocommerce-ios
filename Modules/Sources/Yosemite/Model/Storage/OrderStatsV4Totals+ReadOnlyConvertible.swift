import Foundation
import Storage


// MARK: - Storage.OrderStatsV4Totals: ReadOnlyConvertible
//
extension Storage.OrderStatsV4Totals: ReadOnlyConvertible {

    /// Updates the Storage.OrderStatsV4Totals with the ReadOnly.
    ///
    public func update(with statsTotals: Yosemite.OrderStatsV4Totals) {
        totalOrders = Int64(statsTotals.totalOrders)
        totalItemsSold = Int64(statsTotals.totalItemsSold)
        grossRevenue = NSDecimalNumber(decimal: statsTotals.grossRevenue)
        netRevenue = NSDecimalNumber(decimal: statsTotals.netRevenue)
        averageOrderValue = NSDecimalNumber(decimal: statsTotals.averageOrderValue)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: Int(totalOrders),
                                  totalItemsSold: Int(totalItemsSold),
                                  grossRevenue: grossRevenue.decimalValue,
                                  netRevenue: netRevenue.decimalValue,
                                  averageOrderValue: averageOrderValue.decimalValue)
    }
}
