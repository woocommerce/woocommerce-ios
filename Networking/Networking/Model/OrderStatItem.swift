import Foundation

/// Represents the granularity of a given stat
///
public enum OrderStatGranularity: String {
    case day    = "day"
    case week   = "week"
    case month  = "month"
    case year   = "year"
}

/// Represents an single order stat during a specific period.
///
public struct OrderStatItem: Decodable {
    public let period: String
    public let orders: Int
    public let products: Int
    public let coupons: Int
    public let couponDiscount: Int
    public let totalSales: Int
    public let totalTax: Int
    public let totalShipping: Int
    public let totalShippingTax: Int
    public let totalRefund: Int
    public let totalTaxRefund: Int
    public let totalShippingRefund: Int
    public let totalShippingTaxRefund: Int
    public let currency: String
    public let grossSales: Int
    public let netSales: Int
    public let avgOrderValue: Int
    public let avgProductsPerOrder: Int


    /// OrderStatItem struct initializer.
    ///
    public init(period: String, orders: Int, products: Int, coupons: Int, couponDiscount: Int, totalSales: Int, totalTax: Int, totalShipping: Int,
                totalShippingTax: Int, totalRefund: Int, totalTaxRefund: Int, totalShippingRefund: Int, totalShippingTaxRefund: Int,
                currency: String, grossSales: Int, netSales: Int, avgOrderValue: Int, avgProductsPerOrder: Int) {
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


/// Defines all of the OrderStatItem CodingKeys.
///
private extension OrderStatItem {

    enum CodingKeys: String, CodingKey {
        case period = "period"
        case orders = "orders"
        case products = "products"
        case coupons = "coupons"
        case couponDiscount = "coupon_discount"
        case totalSales = "total_sales"
        case totalTax = "total_tax"
        case totalShipping = "total_shipping"
        case totalShippingTax = "total_shipping_tax"
        case totalRefund = "total_refund"
        case totalTaxRefund = "total_tax_refund"
        case totalShippingRefund = "total_shipping_refund"
        case totalShippingTaxRefund = "total_shipping_tax_refund"
        case currency = "currency"
        case grossSales = "gross_sales"
        case netSales = "net_sales"
        case avgOrderValue = "avg_order_value"
        case avgProductsPerOrder = "avg_products_per_order"
    }
}


// MARK: - Comparable Conformance
//
extension OrderStatItem: Comparable {
    public static func == (lhs: OrderStatItem, rhs: OrderStatItem) -> Bool {
        return lhs.period == rhs.period &&
            lhs.orders == rhs.orders &&
            lhs.products == rhs.products &&
            lhs.coupons == rhs.coupons &&
            lhs.couponDiscount == rhs.couponDiscount &&
            lhs.totalSales == rhs.totalSales &&
            lhs.totalTax == rhs.totalTax &&
            lhs.totalShipping == rhs.totalShipping &&
            lhs.totalShippingTax == rhs.totalShippingTax &&
            lhs.totalRefund == rhs.totalRefund &&
            lhs.totalTaxRefund == rhs.totalTaxRefund &&
            lhs.totalShippingRefund == rhs.totalShippingRefund &&
            lhs.totalShippingTaxRefund == rhs.totalShippingTaxRefund &&
            lhs.currency == rhs.currency &&
            lhs.grossSales == rhs.grossSales &&
            lhs.netSales == rhs.netSales &&
            lhs.avgOrderValue == rhs.avgOrderValue &&
            lhs.avgProductsPerOrder == rhs.avgProductsPerOrder
    }

    public static func < (lhs: OrderStatItem, rhs: OrderStatItem) -> Bool {
        return lhs.period < rhs.period ||
            (lhs.period == rhs.period && lhs.currency < rhs.currency) ||
            (lhs.period == rhs.period && lhs.currency == rhs.currency && lhs.totalSales < rhs.totalSales)
    }
}
