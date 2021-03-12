/// Represents a single order stat for a specific period.
/// v4 API
public struct OrderStatsV4Interval: Decodable, GeneratedFakeable {
    public let interval: String
    /// Interval start date string in the site time zone.
    public let dateStart: String
    /// Interval end date string in the site time zone.
    public let dateEnd: String
    public let subtotals: OrderStatsV4Totals

    public init(interval: String,
                dateStart: String,
                dateEnd: String,
                subtotals: OrderStatsV4Totals) {
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
        let subtotals = try container.decode(OrderStatsV4Totals.self, forKey: .subtotals)

        self.init(interval: interval,
                  dateStart: dateStart,
                  dateEnd: dateEnd,
                  subtotals: subtotals)
    }
}


// MARK: - Conformance to Comparable
//
extension OrderStatsV4Interval: Comparable {
    public static func == (lhs: OrderStatsV4Interval, rhs: OrderStatsV4Interval) -> Bool {
        return lhs.interval == rhs.interval &&
            lhs.dateStart == rhs.dateStart &&
            lhs.dateEnd == rhs.dateEnd &&
            lhs.subtotals == rhs.subtotals
    }

    public static func < (lhs: OrderStatsV4Interval, rhs: OrderStatsV4Interval) -> Bool {
        return lhs.interval < rhs.interval ||
            (lhs.interval == rhs.interval && lhs.subtotals < rhs.subtotals)
    }
}


// MARK: - Constants!
//
private extension OrderStatsV4Interval {
    enum CodingKeys: String, CodingKey {
        case interval = "interval"
        case dateStart = "date_start"
        case dateEnd = "date_end"
        case subtotals = "subtotals"
    }
}
