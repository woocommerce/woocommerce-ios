import Foundation


/// Represents site visit stats over a specific period.
///
public struct SiteVisitStats: Decodable {
    public let date: String
    public let granularity: StatGranularity
    public let fields: [String]
    public let items: [SiteVisitStatsItem]?

    /// The public initializer for order stats.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let date = try container.decode(String.self, forKey: .date)
        let granularity = try container.decode(StatGranularity.self, forKey: .unit)

        let fields = try container.decode([String].self, forKey: .fields)
        let rawData: [[AnyCodable]] = try container.decode([[AnyCodable]].self, forKey: .data)

        let items = rawData.map({ SiteVisitStatsItem(fieldNames: fields, rawData: $0) })

        self.init(date: date, granularity: granularity, fields: fields, items: items)
    }


    /// OrderStats struct initializer.
    ///
    public init(date: String, granularity: StatGranularity, fields: [String], items: [SiteVisitStatsItem]?) {
        self.date = date
        self.granularity = granularity
        self.fields = fields
        self.items = items
    }

    // MARK: Computed Properties

    public var totalVisitors: Int {
        //return items?.reduce(0, {$0 + $1.visitors}) ?? 0
        return items?.compactMap { $0.visitors }.reduce(0, +) ?? 0
    }
}


/// Defines all of the SiteVisitStats CodingKeys.
///
private extension SiteVisitStats {

    enum CodingKeys: String, CodingKey {
        case date = "date"
        case unit = "unit"
        case fields = "fields"
        case data = "data"
    }
}


// MARK: - Comparable Conformance
//
extension SiteVisitStats: Comparable {
    public static func == (lhs: SiteVisitStats, rhs: SiteVisitStats) -> Bool {
        return lhs.date == rhs.date &&
            lhs.granularity == rhs.granularity &&
            lhs.fields == rhs.fields &&
            lhs.items == rhs.items
    }

    public static func < (lhs: SiteVisitStats, rhs: SiteVisitStats) -> Bool {
        return lhs.date < rhs.date
    }
}
