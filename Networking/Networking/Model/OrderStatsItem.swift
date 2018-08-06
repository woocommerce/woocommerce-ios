import Foundation


/// Represents an single order stat for a specific period.
///
public struct OrderStatsItem {
    public let payload: MIContainer

    /// OrderStatsItem struct initializer.
    ///
    public init(fieldNames: [String], rawData: [AnyCodable]) {
        self.payload = MIContainer(data: rawData.map({ $0.value }),
                                   fieldNames: fieldNames)
    }

    // MARK: Computed Properties

    public var period: String {
        return payload.fetchStringValue(for: FieldNames.period)
    }

    public var orders: Int {
        return payload.fetchIntValue(for: FieldNames.orders)
    }

    public var products: Int {
        return payload.fetchIntValue(for: FieldNames.products)
    }

    public var coupons: Int {
        return payload.fetchIntValue(for: FieldNames.coupons)
    }

    public var couponDiscount: Double {
        return payload.fetchDoubleValue(for: FieldNames.couponDiscount)
    }

    public var totalSales: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalSales)
    }

    public var totalTax: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalTax)
    }

    public var totalShipping: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalShipping)
    }

    public var totalShippingTax: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalShippingTax)
    }

    public var totalRefund: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalRefund)
    }

    public var totalTaxRefund: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalTaxRefund)
    }

    public var totalShippingRefund: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalShippingRefund)
    }

    public var totalShippingTaxRefund: Double {
        return payload.fetchDoubleValue(for: FieldNames.totalShippingTaxRefund)
    }

    public var currency: String {
        return payload.fetchStringValue(for: FieldNames.currency)
    }

    public var grossSales: Double {
        return payload.fetchDoubleValue(for: FieldNames.grossSales)
    }

    public var netSales: Double {
        return payload.fetchDoubleValue(for: FieldNames.netSales)
    }

    public var avgOrderValue: Double {
        return payload.fetchDoubleValue(for: FieldNames.avgOrderValue)
    }

    public var avgProductsPerOrder: Double {
        return payload.fetchDoubleValue(for: FieldNames.avgProductsPerOrder)
    }
}


// MARK: - Comparable Conformance
//
extension OrderStatsItem: Comparable {
    public static func == (lhs: OrderStatsItem, rhs: OrderStatsItem) -> Bool {
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

    public static func < (lhs: OrderStatsItem, rhs: OrderStatsItem) -> Bool {
        return lhs.period < rhs.period ||
            (lhs.period == rhs.period && lhs.totalSales < rhs.totalSales) ||
            (lhs.period == rhs.period && lhs.totalSales == rhs.totalSales && lhs.orders < rhs.orders)
    }
}

// MARK: - Constants!
//
private extension OrderStatsItem {

    /// Defines all of the possbile fields for an OrderStatsItem.
    ///
    enum FieldNames: String {
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
