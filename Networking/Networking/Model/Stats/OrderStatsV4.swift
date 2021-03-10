import Foundation

/// Represents order stats over a specific period.
/// v4 API
public struct OrderStatsV4: Decodable, GeneratedFakeable {
    public let siteID: Int64
    public let granularity: StatsGranularityV4
    public let totals: OrderStatsV4Totals
    public let intervals: [OrderStatsV4Interval]

    public init(siteID: Int64,
                granularity: StatsGranularityV4,
                totals: OrderStatsV4Totals,
                intervals: [OrderStatsV4Interval]) {
        self.siteID = siteID
        self.granularity = granularity
        self.totals = totals
        self.intervals = intervals
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw OrderStatsV4APIError.missingSiteID
        }

        guard let granularity = decoder.userInfo[.granularity] as? StatsGranularityV4 else {
            throw OrderStatsV4APIError.missingGranularity
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(OrderStatsV4Totals.self, forKey: .totals)
        let intervals = try container.decode([OrderStatsV4Interval].self, forKey: .intervals)

        self.init(siteID: siteID,
                  granularity: granularity,
                  totals: totals,
                  intervals: intervals)
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


// MARK: - Equatable Conformance
//
extension OrderStatsV4: Equatable {
    public static func == (lhs: OrderStatsV4, rhs: OrderStatsV4) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.granularity == rhs.granularity &&
            lhs.totals == rhs.totals &&
            lhs.intervals == rhs.intervals
    }
}

// MARK: - Decoding Errors
//
enum OrderStatsV4APIError: Error {
    case missingSiteID
    case missingGranularity
}
