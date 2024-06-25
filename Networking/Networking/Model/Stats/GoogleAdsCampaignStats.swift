import Foundation
import Codegen

/// Represents Google Listings & Ads paid campaign stats over a specific period.
public struct GoogleAdsCampaignStats: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let totals: GoogleAdsCampaignStatsTotals

    public init(siteID: Int64,
                totals: GoogleAdsCampaignStatsTotals) {
        self.siteID = siteID
        self.totals = totals
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw GoogleAdsCampaignStatsAPIError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(GoogleAdsCampaignStatsTotals.self, forKey: .totals)

        self.init(siteID: siteID,
                  totals: totals)
    }
}


// MARK: - Constants!
//
private extension GoogleAdsCampaignStats {

    enum CodingKeys: String, CodingKey {
        case totals = "totals"
    }
}

// MARK: - Decoding Errors
//
enum GoogleAdsCampaignStatsAPIError: Error {
    case missingSiteID
}
