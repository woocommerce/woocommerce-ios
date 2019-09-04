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
        couponDiscount = NSDecimalNumber(decimal: statsTotals.couponDiscount)
        totalCoupons = Int64(statsTotals.totalCoupons)
        refunds = NSDecimalNumber(decimal: statsTotals.refunds)
        taxes = NSDecimalNumber(decimal: statsTotals.taxes)
        shipping = NSDecimalNumber(decimal: statsTotals.shipping)
        netRevenue = NSDecimalNumber(decimal: statsTotals.netRevenue)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: Int(totalOrders),
                                  totalItemsSold: Int(totalItemsSold),
                                  grossRevenue: grossRevenue.decimalValue,
                                  couponDiscount: couponDiscount.decimalValue,
                                  totalCoupons: Int(totalCoupons),
                                  refunds: refunds.decimalValue,
                                  taxes: taxes.decimalValue,
                                  shipping: shipping.decimalValue,
                                  netRevenue: netRevenue.decimalValue,
                                  totalProducts: Int(totalProducts))
    }
}
