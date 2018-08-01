import Foundation


/// Represents an single order stat during a specific period.
///
public struct OrderStatsItem: Decodable {
    public let data: [AnyCodable]

    /// OrderStatsItem struct initializer.
    ///
    public init(data: [AnyCodable]) {
        self.data = data
    }

    /// The public initializer for OrderStatsItem.
    ///
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let data = try container.decode([AnyCodable].self)
        self.init(data: data) // initialize the struct
    }
}


// MARK: - Equatable Conformance
//
extension OrderStatsItem: Equatable {
    public static func == (lhs: OrderStatsItem, rhs: OrderStatsItem) -> Bool {
        return lhs.data == rhs.data
    }
}


// MARK: - Constants!
//
private extension OrderStatsItem {

    /// Defines all of the possbile fields for an OrderStatsItem.
    ///
    enum Fields: String {
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
