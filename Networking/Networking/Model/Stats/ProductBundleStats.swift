#if os(iOS)

import Foundation
import Codegen

/// Represents product bundle stats over a specific period.
public struct ProductBundleStats: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, WCAnalyticsStats {
    public let siteID: Int64
    public let granularity: StatsGranularityV4
    public let totals: ProductBundleStatsTotals
    public let intervals: [ProductBundleStatsInterval]

    public init(siteID: Int64,
                granularity: StatsGranularityV4,
                totals: ProductBundleStatsTotals,
                intervals: [ProductBundleStatsInterval]) {
        self.siteID = siteID
        self.granularity = granularity
        self.totals = totals
        self.intervals = intervals
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductBundleStatsAPIError.missingSiteID
        }

        guard let granularity = decoder.userInfo[.granularity] as? StatsGranularityV4 else {
            throw ProductBundleStatsAPIError.missingGranularity
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(ProductBundleStatsTotals.self, forKey: .totals)
        let intervals = try container.decode([ProductBundleStatsInterval].self, forKey: .intervals)

        self.init(siteID: siteID,
                  granularity: granularity,
                  totals: totals,
                  intervals: intervals)
    }
}


// MARK: - Constants!
//
private extension ProductBundleStats {

    enum CodingKeys: String, CodingKey {
        case totals = "totals"
        case intervals = "intervals"
    }
}

// MARK: - Decoding Errors
//
enum ProductBundleStatsAPIError: Error {
    case missingSiteID
    case missingGranularity
}

#endif
