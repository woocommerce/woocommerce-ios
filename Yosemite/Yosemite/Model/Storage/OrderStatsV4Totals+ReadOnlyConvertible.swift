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
        grossRevenue = statsTotals.grossRevenue
        couponDiscount = statsTotals.couponDiscount
        totalCoupons = Int64(statsTotals.totalCoupons)
        refunds = statsTotals.refunds
        taxes = statsTotals.taxes
        shipping = statsTotals.shipping
        netRevenue = statsTotals.netRevenue
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: Int(totalOrders),
                                  totalItemsSold: Int(totalItemsSold),
                                  grossRevenue: grossRevenue,
                                  couponDiscount: couponDiscount,
                                  totalCoupons: Int(totalCoupons),
                                  refunds: refunds,
                                  taxes: taxes,
                                  shipping: shipping,
                                  netRevenue: netRevenue,
                                  totalProducts: Int(totalProducts))
    }
}
