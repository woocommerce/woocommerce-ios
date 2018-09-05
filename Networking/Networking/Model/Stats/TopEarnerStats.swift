import Foundation


/// Represents Top Earner (aka top performer) stats over a specific period.
///
public struct TopEarnerStats: Decodable {
    public let period: String
    public let granularity: StatGranularity
    public let limit: String
    public let items: [TopEarnerStatsItem]?


    /// The public initializer for top earner stats.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let period = try container.decode(String.self, forKey: .period)
        let granularity = try container.decode(StatGranularity.self, forKey: .unit)
        let limit = try container.decode(String.self, forKey: .limit)
        let items = try container.decode([TopEarnerStatsItem].self, forKey: .items)

        self.init(period: period, granularity: granularity, limit: limit, items: items)
    }


    /// TopEarnerStats struct initializer.
    ///
    public init(period: String, granularity: StatGranularity, limit: String, items: [TopEarnerStatsItem]?) {
        self.period = period
        self.granularity = granularity
        self.limit = limit
        self.items = items
    }
}


/// Defines all of the TopEarnerStats CodingKeys.
///
private extension TopEarnerStats {
    enum CodingKeys: String, CodingKey {
        case period = "date"
        case unit = "unit"
        case limit = "limit"
        case items = "data"
    }
}


// MARK: - Comparable Conformance
//
extension TopEarnerStats: Comparable {
    public static func == (lhs: TopEarnerStats, rhs: TopEarnerStats) -> Bool {
        return lhs.period == rhs.period &&
            lhs.granularity == rhs.granularity &&
            lhs.limit == rhs.limit &&
            lhs.items == rhs.items
    }

    public static func < (lhs: TopEarnerStats, rhs: TopEarnerStats) -> Bool {
        return lhs.period < rhs.period ||
            (lhs.period == rhs.period && lhs.limit < rhs.limit)
    }
}
