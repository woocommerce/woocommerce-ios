import Codegen
import Foundation

/// Represents the data associated with order stats over a specific period.
/// v4
public struct OrderStatsV4Totals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, WCAnalyticsStatsTotals {
    public let totalOrders: Int
    public let totalItemsSold: Int
    /// Maps to the API's `total_sales` — the UI labels this as "Total" revenue.
    public let grossRevenue: Decimal
    /// Maps to the API's `gross_sales` — the UI labels this as "Gross" revenue.
    /// Defaults to 0 when the field is missing from older fixtures or backends.
    public let grossSales: Decimal
    public let netRevenue: Decimal
    public let averageOrderValue: Decimal

    public init(totalOrders: Int,
                totalItemsSold: Int,
                grossRevenue: Decimal,
                grossSales: Decimal,
                netRevenue: Decimal,
                averageOrderValue: Decimal) {
        self.totalOrders = totalOrders
        self.totalItemsSold = totalItemsSold
        self.grossRevenue = grossRevenue
        self.grossSales = grossSales
        self.netRevenue = netRevenue
        self.averageOrderValue = averageOrderValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totalOrders = try container.decode(Int.self, forKey: .ordersCount)
        let totalItemsSold = try container.decode(Int.self, forKey: .itemsSold)
        let grossRevenue = try container.decode(Decimal.self, forKey: .grossRevenue)
        let grossSales = try container.decodeIfPresent(Decimal.self, forKey: .grossSales) ?? 0
        let netRevenue = try container.decode(Decimal.self, forKey: .netRevenue)
        let averageOrderValue = try container.decode(Decimal.self, forKey: .averageOrderValue)

        self.init(totalOrders: totalOrders,
                  totalItemsSold: totalItemsSold,
                  grossRevenue: grossRevenue,
                  grossSales: grossSales,
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
        case grossSales = "gross_sales"
        case netRevenue = "net_revenue"
        case averageOrderValue = "avg_order_value"
    }
}
