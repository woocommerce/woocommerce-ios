import Foundation

/// Represents order stats over a specific period.
/// v4 API
public struct OrderStatsV4: Decodable {
    public let totals: OrderStatsV4Totals
    public let intervals: [OrderStatsV4Interval]

    public init(totals: OrderStatsV4Totals,
                intervals: [OrderStatsV4Interval]) {
        self.totals = totals
        self.intervals = intervals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(OrderStatsV4Totals.self, forKey: .totals)
        let intervals = try container.decode([OrderStatsV4Interval].self, forKey: .intervals)

        self.init(totals: totals, intervals: intervals)
    }
}


// MARK: - Constants!
//
private extension OrderStatsV4 {

    enum CodingKeys: String, CodingKey {
        case totals = "totals"
        case intervals = "intervals"
    }
}
