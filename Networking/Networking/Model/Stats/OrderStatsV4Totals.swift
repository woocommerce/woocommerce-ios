import Codegen

/// Represents the data associated with order stats over a specific period.
/// v4
public struct OrderStatsV4Totals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
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

extension OrderStatsV4Totals: WCAnalyticsStatsTotals {
    /// Represents a type of orders total data
    public enum TotalData: String {
        case totalOrders
        case totalItemsSold
        case grossRevenue
        case netRevenue
        case averageOrderValue
    }

    public func getDoubleValue(for data: TotalData) -> Double {
        switch data {
        case .totalOrders:
            return Double(totalOrders)
        case .totalItemsSold:
            return Double(totalItemsSold)
        case .grossRevenue:
            return (grossRevenue as NSNumber).doubleValue
        case .netRevenue:
            return (netRevenue as NSNumber).doubleValue
        case .averageOrderValue:
            return (averageOrderValue as NSNumber).doubleValue
        }
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
