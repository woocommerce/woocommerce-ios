import Foundation
import Codegen

/// Represents Google Listings & Ads paid campaign stats over a specific period.
public struct GoogleAdsCampaignStats: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let totals: GoogleAdsCampaignStatsTotals
    public let campaigns: [GoogleAdsCampaignStatsItem]

    public init(siteID: Int64,
                totals: GoogleAdsCampaignStatsTotals,
                campaigns: [GoogleAdsCampaignStatsItem]) {
        self.siteID = siteID
        self.totals = totals
        self.campaigns = campaigns
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw GoogleAdsCampaignStatsAPIError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(GoogleAdsCampaignStatsTotals.self, forKey: .totals)
        // Campaigns are `nil` if there are no campaigns; we convert this to an empty array.
        let campaigns = (try? container.decode([GoogleAdsCampaignStatsItem].self, forKey: .campaigns)) ?? []

        self.init(siteID: siteID,
                  totals: totals,
                  campaigns: campaigns)
    }
}


// MARK: - Constants!
//
private extension GoogleAdsCampaignStats {

    enum CodingKeys: String, CodingKey {
        case totals
        case campaigns
    }
}

// MARK: - Decoding Errors
//
enum GoogleAdsCampaignStatsAPIError: Error {
    case missingSiteID
}
