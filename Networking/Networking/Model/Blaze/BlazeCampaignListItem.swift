import Foundation
import Codegen

/// Brief information of a Blaze Campaign used in list screen
///
public struct BlazeCampaignListItem: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Site Identifier.
    ///
    public let siteID: Int64

    /// ID of the campaign
    public let campaignID: String

    /// ID of the product in the campaign
    public let productID: Int64?

    /// Name of the campaign
    public let name: String

    /// Text description of the campaign
    public let textSnippet: String

    /// Raw status of the campaign to show to users.
    public let uiStatus: String

    /// URL of the image for the campaign
    public let imageURL: String?

    /// URL of the campaign content
    public let targetUrl: String?

    /// Total impression of the campaign
    public let impressions: Int64

    /// Total clicks on the campaign
    public let clicks: Int64

    /// Budget for the campaign
    public let totalBudget: Double

    /// Spent budget
    public let spentBudget: Double

    public init(siteID: Int64,
                campaignID: String,
                productID: Int64?,
                name: String,
                textSnippet: String,
                uiStatus: String,
                imageURL: String?,
                targetUrl: String?,
                impressions: Int64,
                clicks: Int64,
                totalBudget: Double,
                spentBudget: Double) {
        self.siteID = siteID
        self.campaignID = campaignID
        self.productID = productID
        self.name = name
        self.textSnippet = textSnippet
        self.uiStatus = uiStatus
        self.imageURL = imageURL
        self.targetUrl = targetUrl
        self.impressions = impressions
        self.clicks = clicks
        self.totalBudget = totalBudget
        self.spentBudget = spentBudget
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw DecodingError.missingSiteID
        }

        self.siteID = siteID

        let container = try decoder.container(keyedBy: CodingKeys.self)
        campaignID = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .siteName)
        textSnippet = try container.decodeIfPresent(String.self, forKey: .textSnippet) ?? ""
        uiStatus = try container.decode(String.self, forKey: .status)

        let targetUrn = try container.decode(String.self, forKey: .targetUrn)
        /// Extracts the product ID from the `target_urn` response.
        /// The response looks like the following: `urn:wpcom:post:1:134`
        /// The product ID is the last number following the colon in the response (`134`).
        /// If the product ID cannot be extracted, it returns null instead.
        productID = Int64(String(targetUrn.split(separator: ":").last ?? ""))

        imageURL = try container.decodeIfPresent(Image.self, forKey: .mainImage)?.url
        targetUrl = try container.decodeIfPresent(String.self, forKey: .targetUrl)

        impressions = try container.decodeIfPresent(Int64.self, forKey: .impressions) ?? 0
        clicks = try container.decodeIfPresent(Int64.self, forKey: .clicks) ?? 0
        totalBudget = try container.decode(Double.self, forKey: .totalBudget)
        spentBudget = try container.decodeIfPresent(Double.self, forKey: .spentBudget) ?? 0
    }
}

// MARK: Public subtypes
//
public extension BlazeCampaignListItem {
    enum Status: String {
        case scheduled
        case created
        case rejected
        case approved
        case active
        case canceled
        case finished
        case processing
        case unknown
    }

    /// Status of the current campaign.
    var status: Status {
        Status(rawValue: uiStatus) ?? .unknown
    }
}

// MARK: Private subtypes
//
private extension BlazeCampaignListItem {
    enum CodingKeys: String, CodingKey {
        case id
        case siteName
        case textSnippet
        case targetUrn
        case targetUrl
        case status
        case mainImage
        case totalBudget
        case spentBudget
        case impressions
        case clicks
    }

    /// Private subtype for parsing image details.
    struct Image: Decodable {
        public let url: String?
    }

    /// Decoding Errors
    enum DecodingError: Error {
        case missingSiteID
    }
}
