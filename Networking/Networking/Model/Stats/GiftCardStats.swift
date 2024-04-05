import Foundation
import Codegen

/// Represents gift card stats over a specific period.
public struct GiftCardStats: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, WCAnalyticsStats {
    public let siteID: Int64
    public let granularity: StatsGranularityV4
    public let totals: GiftCardStatsTotals
    public let intervals: [GiftCardStatsInterval]

    public init(siteID: Int64,
                granularity: StatsGranularityV4,
                totals: GiftCardStatsTotals,
                intervals: [GiftCardStatsInterval]) {
        self.siteID = siteID
        self.granularity = granularity
        self.totals = totals
        self.intervals = intervals
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw GiftCardStatsAPIError.missingSiteID
        }

        guard let granularity = decoder.userInfo[.granularity] as? StatsGranularityV4 else {
            throw GiftCardStatsAPIError.missingGranularity
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(GiftCardStatsTotals.self, forKey: .totals)
        let intervals = try container.decode([GiftCardStatsInterval].self, forKey: .intervals)

        self.init(siteID: siteID,
                  granularity: granularity,
                  totals: totals,
                  intervals: intervals)
    }
}


// MARK: - Constants!
//
private extension GiftCardStats {

    enum CodingKeys: String, CodingKey {
        case totals = "totals"
        case intervals = "intervals"
    }
}

// MARK: - Decoding Errors
//
enum GiftCardStatsAPIError: Error {
    case missingSiteID
    case missingGranularity
}
