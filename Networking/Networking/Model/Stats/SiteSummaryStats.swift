import Foundation
import Codegen

/// Represents site summary stats for a specific period.
///
public struct SiteSummaryStats: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let date: String
    public let period: StatGranularity
    public let visitors: Int
    public let views: Int

    /// The public initializer for site summary stats.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw SiteSummaryStatsError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let date = try container.decode(String.self, forKey: .date)
        let period = try container.decode(StatGranularity.self, forKey: .period)
        let visitors = try container.decode(Int.self, forKey: .visitors)
        let views = try container.decode(Int.self, forKey: .views)

        self.init(siteID: siteID, date: date, period: period, visitors: visitors, views: views)
    }

    /// SiteSummaryStats struct initializer.
    ///
    public init(siteID: Int64, date: String, period: StatGranularity, visitors: Int, views: Int) {
        self.siteID = siteID
        self.date = date
        self.period = period
        self.visitors = visitors
        self.views = views
    }
}

/// Defines all of the SiteSummaryStats CodingKeys.
///
private extension SiteSummaryStats {

    enum CodingKeys: String, CodingKey {
        case date
        case period
        case visitors
        case views
    }
}

// MARK: - Decoding Errors
//
enum SiteSummaryStatsError: Error {
    case missingSiteID
}
