import Codegen

/// Represents product bundle stats for a specific period.
public struct ProductBundleStatsInterval: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, WCAnalyticsStatsInterval {
    public let interval: String
    /// Interval start date string in the site time zone.
    public let dateStart: String
    /// Interval end date string in the site time zone.
    public let dateEnd: String
    public let subtotals: ProductBundleStatsTotals

    public init(interval: String,
                dateStart: String,
                dateEnd: String,
                subtotals: ProductBundleStatsTotals) {
        self.interval = interval
        self.dateStart = dateStart
        self.dateEnd = dateEnd
        self.subtotals = subtotals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let interval = try container.decode(String.self, forKey: .interval)
        let dateStart = try container.decode(String.self, forKey: .dateStart)
        let dateEnd = try container.decode(String.self, forKey: .dateEnd)
        let subtotals = try container.decode(ProductBundleStatsTotals.self, forKey: .subtotals)

        self.init(interval: interval,
                  dateStart: dateStart,
                  dateEnd: dateEnd,
                  subtotals: subtotals)
    }
}


// MARK: - Constants!
//
private extension ProductBundleStatsInterval {
    enum CodingKeys: String, CodingKey {
        case interval = "interval"
        case dateStart = "date_start"
        case dateEnd = "date_end"
        case subtotals = "subtotals"
    }
}
