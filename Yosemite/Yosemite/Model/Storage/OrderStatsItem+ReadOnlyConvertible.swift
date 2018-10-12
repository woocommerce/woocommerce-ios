import Foundation
import Storage


// MARK: - Storage.OrderStatsItem: ReadOnlyConvertible
//
extension Storage.OrderStatsItem: ReadOnlyConvertible {

    /// Updates the Storage.OrderStatsItem with the ReadOnly.
    ///
    public func update(with statsItem: Yosemite.OrderStatsItem) {
        period = statsItem.period
        orders = Int64(statsItem.orders)
        products = Int64(statsItem.products)
        coupons = Int64(statsItem.coupons)
        couponDiscount = statsItem.couponDiscount
        totalSales = statsItem.totalSales
        totalTax = statsItem.totalTax
        totalShipping = statsItem.totalShipping
        totalShippingTax = statsItem.totalShippingTax
        totalRefund = statsItem.totalRefund
        totalTaxRefund = statsItem.totalTaxRefund
        totalShippingRefund = statsItem.totalShippingRefund
        totalShippingTaxRefund = statsItem.totalShippingTaxRefund
        currency = statsItem.currency
        grossSales = statsItem.grossSales
        netSales = statsItem.netSales
        avgOrderValue = statsItem.avgOrderValue
        avgProductsPerOrder = statsItem.avgProductsPerOrder
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStatsItem {
        return OrderStatsItem(period: period ?? "",
                              orders: Int(orders),
                              products: Int(products),
                              coupons: Int(coupons),
                              couponDiscount: couponDiscount,
                              totalSales: totalSales,
                              totalTax: totalTax,
                              totalShipping: totalShipping,
                              totalShippingTax: totalShippingTax,
                              totalRefund: totalRefund,
                              totalTaxRefund: totalTaxRefund,
                              totalShippingRefund: totalShippingRefund,
                              totalShippingTaxRefund: totalShippingTaxRefund,
                              currency: currency ?? "",
                              grossSales: grossSales,
                              netSales: netSales,
                              avgOrderValue: avgOrderValue,
                              avgProductsPerOrder: avgProductsPerOrder)
    }
}
