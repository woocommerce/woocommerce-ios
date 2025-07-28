import Codegen
import Foundation

/// Represents the data associated with order stats over a specific period.
/// v4
public struct OrderStatsV4Totals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, WCAnalyticsStatsTotals {
    public let totalOrders: Int
    public let totalItemsSold: Int
    public let grossRevenue: Decimal
    public let netRevenue: Decimal
    public let averageOrderValue: Decimal

    public init(totalOrders: Int,
                totalItemsSold: Int,
                grossRevenue: Decimal,
                netRevenue: Decimal,
                averageOrderValue: Decimal) {
        self.totalOrders = totalOrders
        self.totalItemsSold = totalItemsSold
        self.grossRevenue = grossRevenue
        self.netRevenue = netRevenue
        self.averageOrderValue = averageOrderValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totalOrders = try container.decode(Int.self, forKey: .ordersCount)
        let totalItemsSold = try container.decode(Int.self, forKey: .itemsSold)
        let grossRevenue = try container.decode(Decimal.self, forKey: .grossRevenue)
        let netRevenue = try container.decode(Decimal.self, forKey: .netRevenue)
        let averageOrderValue = try container.decode(Decimal.self, forKey: .averageOrderValue)

        self.init(totalOrders: totalOrders,
                  totalItemsSold: totalItemsSold,
                  grossRevenue: grossRevenue,
                  netRevenue: netRevenue,
                  averageOrderValue: averageOrderValue)
    }
}


// MARK: - Constants!
//
private extension OrderStatsV4Totals {
    enum CodingKeys: String, CodingKey {
        case ordersCount = "orders_count"
        case itemsSold = "num_items_sold"
        case grossRevenue = "total_sales"
        case netRevenue = "net_revenue"
        case averageOrderValue = "avg_order_value"
    }
}
