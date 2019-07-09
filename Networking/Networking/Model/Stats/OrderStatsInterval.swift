import Foundation

/// Represents an single order stat for a specific period.
/// v4 API
public struct OrderStatsInterval: Decodable {
    public let interval: String
    public let dateStart: String
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

extension OrderStatsInterval: Comparable {
    public static func == (lhs: OrderStatsInterval, rhs: OrderStatsInterval) -> Bool {
        return lhs.interval == rhs.interval &&
            lhs.dateStart == rhs.dateStart &&
            lhs.dateEnd == rhs.dateEnd &&
            lhs.subtotals == rhs.subtotals
    }

    public static func < (lhs: OrderStatsInterval, rhs: OrderStatsInterval) -> Bool {
        return lhs.interval < rhs.interval ||
            (lhs.interval == rhs.interval && lhs.subtotals < rhs.subtotals)
    }
}

private extension OrderStatsInterval {
    enum CodingKeys: String, CodingKey {
        case interval = "interval"
        case dateStart = "date_start"
        case dateEnd = "date_end"
        case subtotals = "subtotals"
    }
}


public struct OrderStatsV4: Decodable {
    public let totals: OrderStatsV4Totals
    public let intervals: [OrderStatsInterval]

    public init(totals: OrderStatsV4Totals,
                intervals: [OrderStatsInterval]) {
        self.totals = totals
        self.intervals = intervals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(OrderStatsV4Totals.self, forKey: .totals)
        let intervals = try container.decode([OrderStatsInterval].self, forKey: .intervals)

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

