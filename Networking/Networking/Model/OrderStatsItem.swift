import Foundation


/// Represents an single order stat for a specific period.
///
public struct OrderStatsItem {
    public let data: [Any]
    public let fieldNames: [String]


    /// OrderStatsItem struct initializer.
    ///
    public init(fieldNames: [String], rawData: [AnyCodable]) {
        self.fieldNames = fieldNames
        self.data = rawData.map({ $0.value })
    }

    // MARK: Computed Properties

    public var period: String {
        return fetchStringValue(for: .period)
    }

    public var orders: Int {
        return fetchIntValue(for: .orders)
    }

    public var products: Int {
        return fetchIntValue(for: .products)
    }

    public var coupons: Int {
        return fetchIntValue(for: .coupons)
    }

    public var couponDiscount: Double {
        return fetchDoubleValue(for: .couponDiscount)
    }

    public var totalSales: Double {
        return fetchDoubleValue(for: .totalSales)
    }

    public var totalTax: Double {
        return fetchDoubleValue(for: .totalTax)
    }

    public var totalShipping: Double {
        return fetchDoubleValue(for: .totalShipping)
    }

    public var totalShippingTax: Double {
        return fetchDoubleValue(for: .totalShippingTax)
    }

    public var totalRefund: Double {
        return fetchDoubleValue(for: .totalRefund)
    }

    public var totalTaxRefund: Double {
        return fetchDoubleValue(for: .totalTaxRefund)
    }

    public var totalShippingRefund: Double {
        return fetchDoubleValue(for: .totalShippingRefund)
    }

    public var totalShippingTaxRefund: Double {
        return fetchDoubleValue(for: .totalShippingTaxRefund)
    }

    public var currency: String {
        return fetchStringValue(for: .currency)
    }

    public var grossSales: Double {
        return fetchDoubleValue(for: .grossSales)
    }

    public var netSales: Double {
        return fetchDoubleValue(for: .netSales)
    }

    public var avgOrderValue: Double {
        return fetchDoubleValue(for: .avgOrderValue)
    }

    public var avgProductsPerOrder: Double {
        return fetchDoubleValue(for: .avgProductsPerOrder)
    }
}


// MARK: - Comparable Conformance
//
extension OrderStatsItem: Comparable {
    public static func == (lhs: OrderStatsItem, rhs: OrderStatsItem) -> Bool {
        return lhs.fieldNames == rhs.fieldNames &&
            lhs.period == rhs.period &&
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

// MARK: - Private Helpers
//

private extension OrderStatsItem {
    func fetchStringValue(for field: FieldNames) -> String {
        guard let index = fieldNames.index(of: field.rawValue) else {
            return ""
        }

        // 😢 As crazy as it sounds, sometimes the server occasionally returns
        // String values as Ints — we need to account for this.
        if self.data[index] is Int {
            if let intValue = self.data[index] as? Int {
                return String(intValue)
            }
            return ""
        } else {
            return self.data[index] as? String ?? ""
        }
    }

    func fetchIntValue(for field: FieldNames) -> Int {
        guard let index = fieldNames.index(of: field.rawValue),
            let returnValue = self.data[index] as? Int else {
                return 0
        }
        return returnValue
    }

    func fetchDoubleValue(for field: FieldNames) -> Double {
        guard let index = fieldNames.index(of: field.rawValue) else {
            return 0
        }

        if self.data[index] is Int {
            let intValue = self.data[index] as? Int ?? 0
            return Double(intValue)
        } else {
            return self.data[index] as? Double ?? 0
        }
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
