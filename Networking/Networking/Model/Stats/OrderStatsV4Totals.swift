/// Represents the data associated with order stats over a specific period.
/// v4
public struct OrderStatsV4Totals: Decodable {
    public let totalOrders: Int
    public let totalItemsSold: Int
    public let grossRevenue: Decimal
    public let couponDiscount: Decimal
    public let totalCoupons: Int
    public let refunds: Decimal
    public let taxes: Decimal
    public let shipping: Decimal
    public let netRevenue: Decimal
    public let totalProducts: Int?

    public init(totalOrders: Int,
                totalItemsSold: Int,
                grossRevenue: Decimal,
                couponDiscount: Decimal,
                totalCoupons: Int,
                refunds: Decimal,
                taxes: Decimal,
                shipping: Decimal,
                netRevenue: Decimal,
                totalProducts: Int?) {
        self.totalOrders = totalOrders
        self.totalItemsSold = totalItemsSold
        self.grossRevenue = grossRevenue
        self.couponDiscount = couponDiscount
        self.totalCoupons = totalCoupons
        self.refunds = refunds
        self.taxes = taxes
        self.shipping = shipping
        self.netRevenue = netRevenue
        self.totalProducts = totalProducts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totalOrders = try container.decode(Int.self, forKey: .ordersCount)
        let totalItemsSold = try container.decode(Int.self, forKey: .itemsSold)
        let grossRevenue = try container.decode(Decimal.self, forKey: .grossRevenue)
        let couponDiscount = try container.decode(Decimal.self, forKey: .couponDiscount)
        let totalCoupons = try container.decode(Int.self, forKey: .coupons)
        let refunds = try container.decode(Decimal.self, forKey: .refunds)
        let taxes = try container.decode(Decimal.self, forKey: .taxes)
        let shipping = try container.decode(Decimal.self, forKey: .shipping)
        let netRevenue = try container.decode(Decimal.self, forKey: .netRevenue)
        let totalProducts = try container.decodeIfPresent(Int.self, forKey: .products)

        self.init(totalOrders: totalOrders,
                  totalItemsSold: totalItemsSold,
                  grossRevenue: grossRevenue,
                  couponDiscount: couponDiscount,
                  totalCoupons: totalCoupons,
                  refunds: refunds,
                  taxes: taxes,
                  shipping: shipping,
                  netRevenue: netRevenue,
                  totalProducts: totalProducts)
    }
}


// MARK: - Conformance to Equatable
//
extension OrderStatsV4Totals: Equatable {
    public static func == (lhs: OrderStatsV4Totals, rhs: OrderStatsV4Totals) -> Bool {
        return lhs.totalOrders == rhs.totalOrders &&
            lhs.totalItemsSold == rhs.totalItemsSold &&
            lhs.grossRevenue == rhs.grossRevenue &&
            lhs.couponDiscount == rhs.couponDiscount &&
            lhs.totalCoupons == rhs.totalCoupons &&
            lhs.refunds == rhs.refunds &&
            lhs.taxes == rhs.taxes &&
            lhs.shipping == rhs.shipping &&
            lhs.netRevenue == rhs.netRevenue &&
            lhs.totalProducts == rhs.totalProducts
    }

    public static func < (lhs: OrderStatsV4Totals, rhs: OrderStatsV4Totals) -> Bool {
        return lhs.grossRevenue < rhs.grossRevenue ||
            (lhs.grossRevenue == rhs.grossRevenue && lhs.totalOrders < rhs.totalOrders)
    }
}


// MARK: - Constants!
//
private extension OrderStatsV4Totals {
    enum CodingKeys: String, CodingKey {
        case ordersCount = "orders_count"
        case itemsSold = "num_items_sold"
        case grossRevenue = "total_sales"
        case couponDiscount = "coupons"
        case coupons = "coupons_count"
        case refunds
        case taxes
        case shipping
        case netRevenue = "net_revenue"
        case products
    }
}
