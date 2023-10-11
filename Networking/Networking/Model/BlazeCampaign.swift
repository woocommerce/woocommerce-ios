import Foundation
import Codegen

/// Ads campaign powered by Blaze
///
public final class BlazeCampaign: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// Site Identifier.
    ///
    public let siteID: Int64

    /// ID of the campaign
    public let campaignID: Int64

    /// Name of the campaign
    public let name: String

    /// Status of the campaign to show to users.
    public let uiStatus: String

    /// URL of the image for the campaign
    public let contentImageURL: String?

    /// URL of the campaign content
    public let contentClickURL: String?

    /// Total impression of the campaign
    public let totalImpressions: Int64

    /// Total clicks on the campaign
    public let totalClicks: Int64

    /// Total budget for the campaign
    public let totalBudget: Double

    public init(siteID: Int64,
                campaignID: Int64,
                name: String,
                uiStatus: String,
                contentImageURL: String?,
                contentClickURL: String?,
                totalImpressions: Int64,
                totalClicks: Int64,
                totalBudget: Double) {
        self.siteID = siteID
        self.campaignID = campaignID
        self.name = name
        self.uiStatus = uiStatus
        self.contentImageURL = contentImageURL
        self.contentClickURL = contentClickURL
        self.totalImpressions = totalImpressions
        self.totalClicks = totalClicks
        self.totalBudget = totalBudget
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw DecodingError.missingSiteID
        }

        self.siteID = siteID

        let container = try decoder.container(keyedBy: CodingKeys.self)
        campaignID = try container.decode(Int64.self, forKey: .campaignID)
        name = try container.decode(String.self, forKey: .name)
        uiStatus = try container.decode(String.self, forKey: .uiStatus)

        let content = try container.decode(ContentConfig.self, forKey: .contentConfig)
        contentImageURL = content.imageURL
        contentClickURL = content.clickURL

        let stats = try container.decode(Stats.self, forKey: .stats)
        totalImpressions = stats.totalImpressions
        totalClicks = stats.totalClicks
        totalBudget = stats.totalBudget
    }
}

// MARK: Private subtypes
//
private extension BlazeCampaign {
    enum CodingKeys: String, CodingKey {
        case campaignID = "campaignId"
        case name
        case uiStatus
        case contentConfig
        case stats = "campaignStats"
    }

    /// Private subtype for parsing stat details.
    struct Stats: Decodable {
        public let totalImpressions: Int64
        public let totalClicks: Int64
        public let totalBudget: Double

        enum CodingKeys: String, CodingKey {
            case totalImpressions = "impressions_total"
            case totalClicks = "clicks_total"
            case totalBudget = "total_budget"
        }
    }

    /// Private subtype for parsing content details.
    struct ContentConfig: Decodable {
        public let clickURL: String?
        public let imageURL: String?

        enum CodingKeys: String, CodingKey {
            case clickURL = "clickUrl"
            case imageURL = "imageUrl"
        }
    }

    /// Decoding Errors
    enum DecodingError: Error {
        case missingSiteID
    }
}
