import Foundation

/// Represents an single order stat for a specific period.
///
public struct OrderStatsItem {
    public let period: String
    public let orders: Int
    public let products: Int
    public let coupons: Int
    public let couponDiscount: Double
    public let totalSales: Double
    public let totalTax: Double
    public let totalShipping: Double
    public let totalShippingTax: Double
    public let totalRefund: Double
    public let totalTaxRefund: Double
    public let totalShippingRefund: Double
    public let totalShippingTaxRefund: Double
    public let currency: String
    public let grossSales: Double
    public let netSales: Double
    public let avgOrderValue: Double
    public let avgProductsPerOrder: Double

    /// OrderStatsItem struct initializer.
    ///
    public init(
        period: String, orders: Int, products: Int, coupons: Int, couponDiscount: Double,
        totalSales: Double, totalTax: Double, totalShipping: Double, totalShippingTax: Double,
        totalRefund: Double, totalTaxRefund: Double, totalShippingRefund: Double, totalShippingTaxRefund: Double,
        currency: String, grossSales: Double, netSales: Double, avgOrderValue: Double, avgProductsPerOrder: Double
    ) {
        self.period = period
        self.orders = orders
        self.products = products
        self.coupons = coupons
        self.couponDiscount = couponDiscount
        self.totalSales = totalSales
        self.totalTax = totalTax
        self.totalShipping = totalShipping
        self.totalShippingTax = totalShippingTax
        self.totalRefund = totalRefund
        self.totalTaxRefund = totalTaxRefund
        self.totalShippingRefund = totalShippingRefund
        self.totalShippingTaxRefund = totalShippingTaxRefund
        self.currency = currency
        self.grossSales = grossSales
        self.netSales = netSales
        self.avgOrderValue = avgOrderValue
        self.avgProductsPerOrder = avgProductsPerOrder
    }
}


// MARK: - Comparable Conformance
//
extension OrderStatsItem: Comparable {
    public static func == (lhs: OrderStatsItem, rhs: OrderStatsItem) -> Bool {
        return lhs.period == rhs.period && lhs.orders == rhs.orders && lhs.products == rhs.products && lhs.coupons == rhs.coupons && lhs.couponDiscount == rhs
            .couponDiscount && lhs.totalSales == rhs.totalSales && lhs.totalTax == rhs.totalTax && lhs.totalShipping == rhs.totalShipping && lhs
            .totalShippingTax == rhs.totalShippingTax && lhs.totalRefund == rhs.totalRefund && lhs.totalTaxRefund == rhs.totalTaxRefund && lhs
            .totalShippingRefund == rhs.totalShippingRefund && lhs.totalShippingTaxRefund == rhs.totalShippingTaxRefund && lhs.currency == rhs.currency && lhs
            .grossSales == rhs.grossSales && lhs.netSales == rhs.netSales && lhs.avgOrderValue == rhs.avgOrderValue && lhs.avgProductsPerOrder == rhs
            .avgProductsPerOrder
    }

    public static func < (lhs: OrderStatsItem, rhs: OrderStatsItem) -> Bool {
        return lhs.period < rhs.period || (lhs.period == rhs.period && lhs.totalSales < rhs.totalSales) || (
            lhs.period == rhs.period && lhs.totalSales == rhs.totalSales && lhs.orders < rhs.orders
        )
    }

    public static func > (lhs: OrderStatsItem, rhs: OrderStatsItem) -> Bool {
        return lhs.period > rhs.period || (lhs.period == rhs.period && lhs.totalSales > rhs.totalSales) || (
            lhs.period == rhs.period && lhs.totalSales == rhs.totalSales && lhs.orders > rhs.orders
        )
    }
}
