import Foundation


/// Represents Top Earner (aka top performer) stats over a specific period.
///
public struct TopEarnerStats: Decodable {
    public let date: String
    public let granularity: StatGranularity
    public let limit: String
    public let items: [TopEarnerStatsItem]?


    /// The public initializer for top earner stats.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let date = try container.decode(String.self, forKey: .date)
        let granularity = try container.decode(StatGranularity.self, forKey: .unit)
        let limit = try container.decode(String.self, forKey: .limit)
        let items = try container.decode([TopEarnerStatsItem].self, forKey: .items)

        self.init(date: date, granularity: granularity, limit: limit, items: items)
    }


    /// TopEarnerStats struct initializer.
    ///
    public init(date: String, granularity: StatGranularity, limit: String, items: [TopEarnerStatsItem]?) {
        self.date = date
        self.granularity = granularity
        self.limit = limit
        self.items = items
    }
}


/// Defines all of the TopEarnerStats CodingKeys.
///
private extension TopEarnerStats {
    enum CodingKeys: String, CodingKey {
        case date = "date"
        case unit = "unit"
        case limit = "limit"
        case items = "data"
    }
}


// MARK: - Comparable Conformance
//
extension TopEarnerStats: Comparable {
    public static func == (lhs: TopEarnerStats, rhs: TopEarnerStats) -> Bool {
        return lhs.date == rhs.date &&
            lhs.granularity == rhs.granularity &&
            lhs.limit == rhs.limit &&
            lhs.items?.count == rhs.items?.count &&
            lhs.items?.sorted() == rhs.items?.sorted()
    }

    public static func < (lhs: TopEarnerStats, rhs: TopEarnerStats) -> Bool {
        return lhs.date < rhs.date ||
            (lhs.date == rhs.date && lhs.limit < rhs.limit)
    }
}
