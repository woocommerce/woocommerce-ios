import Foundation
import Codegen

/// Represents the entity sent for creating a new Blaze Campaign
///
public struct CreateBlazeCampaign: Encodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public struct Image: Encodable, Equatable, GeneratedFakeable, GeneratedCopiable {
        /// URL of the image for the campaign
        ///
        public let url: String

        /// mime type of the image
        ///
        public let mimeType: String

        public init(url: String, mimeType: String) {
            self.url = url
            self.mimeType = mimeType
        }
    }

    public struct Targeting: Encodable, Equatable, GeneratedFakeable, GeneratedCopiable {
        /// IDs of locations => GET /locations/search?keyword=city
        ///
        public let locations: [Int64]?

        /// IDs of languages => GET /targeting/languages
        ///
        public let languages: [String]?

        /// IDs of devices => GET /targeting/devices (absent if any)
        ///
        public let devices: [String]?

        /// IDs of pageTopics => GET /targeting/page-topics (absent if any)
        ///
        public let pageTopics: [String]?

        public init(locations: [Int64]?, languages: [String]?, devices: [String]?, pageTopics: [String]?) {
            self.locations = locations
            self.languages = languages
            self.devices = devices
            self.pageTopics = pageTopics
        }
    }

    /// Origin of the campaign creation
    /// Accepted options are calypso, jetpack, wc-mobile-app, wp-mobile-app
    ///
    public let origin: String

    /// See peeHDf-2ii-p2
    ///
    public let paymentMethodID: String

    /// Sample format `2023-12-05`
    /// Including, can't be less than 24 hours after submission time
    ///
    public let startDate: String

    /// Sample format `2023-12-11`
    /// Including
    ///
    public let endDate: String

    /// Time zone identifier (TZ database name).
    ///
    public let timeZone: String

    /// Total campaign budget in USD
    ///
    public let totalBudget: Double

    /// Tagline of the campaign
    ///
    public let siteName: String

    /// Description of the campaign
    ///
    public let textSnippet: String

    /// URL of the campaign
    ///
    public let targetUrl: String

    /// URL parameters of the campaign
    ///
    public let urlParams: String

    /// Image for the campaign
    ///
    public let mainImage: Image

    /// Targeting
    /// Can be nil if no targeting
    ///
    public let targeting: Targeting?

    /// Sample format `urn:wpcom:post:123456:789`
    /// - 123456 is the site ID
    /// - 789 is the product ID
    ///
    public let targetUrn: String

    /// Accepted options - post, page, product
    ///
    public let type: String

    public init(origin: String,
                paymentMethodID: String,
                startDate: String,
                endDate: String,
                timeZone: String,
                totalBudget: Double,
                siteName: String,
                textSnippet: String,
                targetUrl: String,
                urlParams: String,
                mainImage: Image,
                targeting: Targeting?,
                targetUrn: String,
                type: String) {
        self.origin = origin
        self.paymentMethodID = paymentMethodID
        self.startDate = startDate
        self.endDate = endDate
        self.timeZone = timeZone
        self.totalBudget = totalBudget
        self.siteName = siteName
        self.textSnippet = textSnippet
        self.targetUrl = targetUrl
        self.urlParams = urlParams
        self.mainImage = mainImage
        self.targeting = targeting
        self.targetUrn = targetUrn
        self.type = type
    }
}
