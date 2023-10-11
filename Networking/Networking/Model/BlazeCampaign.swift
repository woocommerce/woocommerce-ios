import Foundation
import Codegen

/// Ads campaign powered by Blaze
///
public final class BlazeCampaign: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// ID of the campaign
    public let campaignID: Int64

    /// Name of the campaign
    public let name: String

    /// A raw campaign status on the server.
    public let status: Status

    /// A subset of ``BlazeCampaign/status-swift.property`` values where some
    /// cases are skipped for simplicity and mapped to other more common ones.
    public let uiStatus: Status

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

    public init(campaignID: Int64,
                name: String,
                status: Status,
                uiStatus: Status,
                contentImageURL: String?,
                contentClickURL: String?,
                totalImpressions: Int64,
                totalClicks: Int64,
                totalBudget: Double) {
        self.campaignID = campaignID
        self.name = name
        self.status = status
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

        let container = try decoder.container(keyedBy: CodingKeys.self)
        campaignID = try container.decode(Int64.self, forKey: .campaignID)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(Status.self, forKey: .status)
        uiStatus = try container.decode(Status.self, forKey: .uiStatus)

        let content = try container.decode(ContentConfig.self, forKey: .contentConfig)
        contentImageURL = content.imageURL
        contentClickURL = content.clickURL

        let stats = try container.decode(Stats.self, forKey: .stats)
        totalImpressions = stats.totalImpressions
        totalClicks = stats.totalClicks
        totalBudget = stats.totalBudget
    }
}

// MARK: Public subtypes
//
public extension BlazeCampaign {
    enum Status: String, Decodable {
        case scheduled
        case created
        case rejected
        case approved
        case active
        case canceled
        case finished
        case processing
        case unknown

        public init(from decoder: Decoder) throws {
            let status = try? String(from: decoder)
            self = status.flatMap(Status.init) ?? .unknown
        }
    }
}

// MARK: Private subtypes
//
private extension BlazeCampaign {
    enum CodingKeys: String, CodingKey {
        case campaignID = "campaignId"
        case name
        case status
        case uiStatus
        case budgetCents
        case targetURL = "targetUrl"
        case contentConfig
        case stats = "campaignStats"
        case creativeHTML = "creativeHtml"
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
