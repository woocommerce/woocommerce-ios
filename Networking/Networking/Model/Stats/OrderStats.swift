import Foundation


/// Represents order stats over a specific period.
///
public struct OrderStats: Decodable {
    public let date: String
    public let granularity: StatGranularity
    public let quantity: String
    public let totalGrossSales: Double
    public let totalNetSales: Double
    public let totalOrders: Int
    public let totalProducts: Int
    public let averageGrossSales: Double
    public let averageNetSales: Double
    public let averageOrders: Double
    public let averageProducts: Double
    public let items: [OrderStatsItem]?


    /// The public initializer for order stats.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let date = try container.decode(String.self, forKey: .date)
        let granularity = try container.decode(StatGranularity.self, forKey: .unit)
        let quantity = try container.decode(String.self, forKey: .quantity)

        let totalGrossSales = try container.decode(Double.self, forKey: .totalGrossSales)
        let totalNetSales = try container.decode(Double.self, forKey: .totalNetSales)
        let totalOrders = try container.decode(Int.self, forKey: .totalOrders)
        let totalProducts = try container.decode(Int.self, forKey: .totalProducts)

        let averageGrossSales = try container.decode(Double.self, forKey: .averageGrossSales)
        let averageNetSales = try container.decode(Double.self, forKey: .averageNetSales)
        let averageOrders = try container.decode(Double.self, forKey: .averageOrders)
        let averageProducts = try container.decode(Double.self, forKey: .averageProducts)

        let fieldNames = try container.decode([String].self, forKey: .fields)
        let rawData: [[AnyCodable]] = try container.decode([[AnyCodable]].self, forKey: .data)
        let rawDataContainers = rawData.map({ MIContainer(data: $0.map({ $0.value }), fieldNames: fieldNames) })
        let items = rawDataContainers.map({ OrderStatsItem(period: $0.fetchStringValue(for: ItemFieldNames.period),
                                                           orders: $0.fetchIntValue(for: ItemFieldNames.orders),
                                                           products: $0.fetchIntValue(for: ItemFieldNames.products),
                                                           coupons: $0.fetchIntValue(for: ItemFieldNames.coupons),
                                                           couponDiscount: $0.fetchDoubleValue(for: ItemFieldNames.couponDiscount),
                                                           totalSales: $0.fetchDoubleValue(for: ItemFieldNames.totalSales),
                                                           totalTax: $0.fetchDoubleValue(for: ItemFieldNames.totalTax),
                                                           totalShipping: $0.fetchDoubleValue(for: ItemFieldNames.totalShipping),
                                                           totalShippingTax: $0.fetchDoubleValue(for: ItemFieldNames.totalShippingTax),
                                                           totalRefund: $0.fetchDoubleValue(for: ItemFieldNames.totalRefund),
                                                           totalTaxRefund: $0.fetchDoubleValue(for: ItemFieldNames.totalTaxRefund),
                                                           totalShippingRefund: $0.fetchDoubleValue(for: ItemFieldNames.totalShippingRefund),
                                                           totalShippingTaxRefund: $0.fetchDoubleValue(for: ItemFieldNames.totalShippingTaxRefund),
                                                           currency: $0.fetchStringValue(for: ItemFieldNames.currency),
                                                           grossSales: $0.fetchDoubleValue(for: ItemFieldNames.grossSales),
                                                           netSales: $0.fetchDoubleValue(for: ItemFieldNames.netSales),
                                                           avgOrderValue: $0.fetchDoubleValue(for: ItemFieldNames.avgOrderValue),
                                                           avgProductsPerOrder: $0.fetchDoubleValue(for: ItemFieldNames.avgProductsPerOrder)) })


        self.init(date: date,
                  granularity: granularity,
                  quantity: quantity,
                  items: items,
                  totalGrossSales: totalGrossSales,
                  totalNetSales: totalNetSales,
                  totalOrders: totalOrders,
                  totalProducts: totalProducts,
                  averageGrossSales: averageGrossSales,
                  averageNetSales: averageNetSales,
                  averageOrders: averageOrders,
                  averageProducts: averageProducts)
    }


    /// OrderStats struct initializer.
    ///
    public init(date: String,
                granularity: StatGranularity,
                quantity: String,
                items: [OrderStatsItem]?,
                totalGrossSales: Double,
                totalNetSales: Double,
                totalOrders: Int,
                totalProducts: Int,
                averageGrossSales: Double,
                averageNetSales: Double,
                averageOrders: Double,
                averageProducts: Double) {
        self.date = date
        self.granularity = granularity
        self.quantity = quantity
        self.totalGrossSales = totalGrossSales
        self.totalNetSales = totalNetSales
        self.totalOrders = totalOrders
        self.totalProducts = totalProducts
        self.averageGrossSales = averageGrossSales
        self.averageNetSales = averageNetSales
        self.averageOrders = averageOrders
        self.averageProducts = averageProducts
        self.items = items
    }
}


/// Defines all of the OrderStats CodingKeys.
///
private extension OrderStats {

    enum CodingKeys: String, CodingKey {
        case date = "date"
        case unit = "unit"
        case quantity = "quantity"
        case fields = "fields"
        case data = "data"
        case totalGrossSales = "total_gross_sales"
        case totalNetSales = "total_net_sales"
        case totalOrders = "total_orders"
        case totalProducts = "total_products"
        case averageGrossSales = "avg_gross_sales"
        case averageNetSales = "avg_net_sales"
        case averageOrders = "avg_orders"
        case averageProducts = "avg_products"
    }
}


// MARK: - Comparable Conformance
//
extension OrderStats: Comparable {
    public static func == (lhs: OrderStats, rhs: OrderStats) -> Bool {
        return lhs.date == rhs.date &&
            lhs.granularity == rhs.granularity &&
            lhs.quantity == rhs.quantity &&
            lhs.totalGrossSales == rhs.totalGrossSales &&
            lhs.totalNetSales == rhs.totalNetSales &&
            lhs.totalOrders == rhs.totalOrders &&
            lhs.totalProducts == rhs.totalProducts &&
            lhs.averageGrossSales == rhs.averageGrossSales &&
            lhs.averageNetSales == rhs.averageNetSales &&
            lhs.averageOrders == rhs.averageOrders &&
            lhs.averageProducts == rhs.averageProducts &&
            lhs.items?.count == rhs.items?.count &&
            lhs.items?.sorted() == rhs.items?.sorted()
    }

    public static func < (lhs: OrderStats, rhs: OrderStats) -> Bool {
        return lhs.date < rhs.date ||
            (lhs.date == rhs.date && lhs.quantity < rhs.quantity)
    }
}


// MARK: - Constants!
//
private extension OrderStats {

    /// Defines all of the possbile fields for an OrderStatsItem.
    ///
    enum ItemFieldNames: String {
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
