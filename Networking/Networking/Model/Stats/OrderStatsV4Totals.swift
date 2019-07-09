/// Represents the data assoicated to order stats over a specific period.
/// v4
public struct OrderStatsV4Totals: Decodable {
    public let orders: Int
    public let itemsSold: Int
    public let grossRevenue: Double
    public let couponDiscount: Double
    public let coupons: Int
    public let refunds: Double
    public let taxes: Double
    public let shipping: Double
    public let netRevenue: Double
    public let products: Int?

    public init(orders: Int,
                itemsSold: Int,
                grossRevenue: Double,
                couponDiscount: Double,
                coupons: Int,
                refunds: Double,
                taxes: Double,
                shipping: Double,
                netRevenue: Double,
                products: Int?) {
        self.orders = orders
        self.itemsSold = itemsSold
        self.grossRevenue = grossRevenue
        self.couponDiscount = couponDiscount
        self.coupons = coupons
        self.refunds = refunds
        self.taxes = taxes
        self.shipping = shipping
        self.netRevenue = netRevenue
        self.products = products
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let orders = try container.decode(Int.self, forKey: .ordersCount)
        let itemsSold = try container.decode(Int.self, forKey: .itemsSold)
        let grossRevenue = try container.decode(Double.self, forKey: .grossRevenue)
        let couponDiscount = try container.decode(Double.self, forKey: .couponDiscount)
        let coupons = try container.decode(Int.self, forKey: .coupons)
        let refunds = try container.decode(Double.self, forKey: .refunds)
        let taxes = try container.decode(Double.self, forKey: .taxes)
        let shipping = try container.decode(Double.self, forKey: .shipping)
        let netRevenue = try container.decode(Double.self, forKey: .netRevenue)
        let products = try container.decodeIfPresent(Int.self, forKey: .products)

        self.init(orders: orders,
                  itemsSold: itemsSold,
                  grossRevenue: grossRevenue,
                  couponDiscount: couponDiscount,
                  coupons: coupons,
                  refunds: refunds,
                  taxes: taxes,
                  shipping: shipping,
                  netRevenue: netRevenue,
                  products: products)
    }
}


// MARK: - Conformance to Equatable
//
extension OrderStatsV4Totals: Equatable {
    public static func == (lhs: OrderStatsV4Totals, rhs: OrderStatsV4Totals) -> Bool {
        return lhs.orders == rhs.orders &&
            lhs.itemsSold == rhs.itemsSold &&
            lhs.grossRevenue == rhs.grossRevenue &&
            lhs.couponDiscount == rhs.couponDiscount &&
            lhs.coupons == rhs.coupons &&
            lhs.refunds == rhs.refunds &&
            lhs.taxes == rhs.taxes &&
            lhs.shipping == rhs.shipping &&
            lhs.netRevenue == rhs.netRevenue &&
            lhs.products == rhs.products
    }

    public static func < (lhs: OrderStatsV4Totals, rhs: OrderStatsV4Totals) -> Bool {
        return lhs.grossRevenue < rhs.grossRevenue ||
            (lhs.grossRevenue == rhs.grossRevenue && lhs.orders < rhs.orders)
    }
}


// MARK: - Constants!
//
private extension OrderStatsV4Totals {
    enum CodingKeys: String, CodingKey {
        case ordersCount = "orders_count"
        case itemsSold = "num_items_sold"
        case grossRevenue = "gross_revenue"
        case couponDiscount = "coupons"
        case coupons = "coupons_count"
        case refunds = "refunds"
        case taxes = "taxes"
        case shipping = "shipping"
        case netRevenue = "net_revenue"
        case products = "products"
    }
}
