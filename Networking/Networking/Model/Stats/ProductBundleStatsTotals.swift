import Codegen

/// Represents the data associated with product bundle stats over a specific period.
public struct ProductBundleStatsTotals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, WCAnalyticsStatsTotals {
    public let totalItemsSold: Int
    public let totalBundledItemsSold: Int
    public let netRevenue: Decimal
    public let totalOrders: Int
    public let totalProducts: Int

    public init(totalItemsSold: Int,
                totalBundledItemsSold: Int,
                netRevenue: Decimal,
                totalOrders: Int,
                totalProducts: Int) {
        self.totalItemsSold = totalItemsSold
        self.totalBundledItemsSold = totalBundledItemsSold
        self.netRevenue = netRevenue
        self.totalOrders = totalOrders
        self.totalProducts = totalProducts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totalItemsSold = try container.decode(Int.self, forKey: .itemsSold)
        let bundledItemsSold = try container.decode(Int.self, forKey: .bundledItemsSold)
        let netRevenue = try container.decode(Decimal.self, forKey: .netRevenue)
        let totalOrders = try container.decode(Int.self, forKey: .ordersCount)
        let productsCount = try container.decode(Int.self, forKey: .productsCount)

        self.init(totalItemsSold: totalItemsSold,
                  totalBundledItemsSold: bundledItemsSold,
                  netRevenue: netRevenue,
                  totalOrders: totalOrders,
                  totalProducts: productsCount)
    }
}


// MARK: - Constants!
//
private extension ProductBundleStatsTotals {
    enum CodingKeys: String, CodingKey {
        case itemsSold = "items_sold"
        case bundledItemsSold = "bundled_items_sold"
        case netRevenue = "net_revenue"
        case ordersCount = "orders_count"
        case productsCount = "products_count"
    }
}
