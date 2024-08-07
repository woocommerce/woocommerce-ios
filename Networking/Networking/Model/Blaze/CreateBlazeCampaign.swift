import Foundation
import Codegen

/// Represents the entity sent for creating a new Blaze Campaign
///
public struct CreateBlazeCampaign: Encodable, GeneratedFakeable, GeneratedCopiable {
    public struct Image: Encodable, GeneratedFakeable, GeneratedCopiable {
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

    /// Origin of the campaign creation
    /// Accepted options are calypso, jetpack, wc-mobile-app, wp-mobile-app
    ///
    public let origin: String

    /// App version to track origin
    ///
    public let originVersion: String

    /// See peeHDf-2ii-p2
    ///
    public let paymentMethodID: String

    /// Start date of the campaign
    ///
    /// Including, can't be less than 24 hours after submission time
    ///
    public let startDate: Date

    /// End date of the campaign
    ///
    /// Including
    ///
    public let endDate: Date

    /// Time zone identifier (TZ database name).
    ///
    public let timeZone: String

    /// Campaign budget with specified amount, currency, and mode.
    ///
    public let budget: BlazeCampaignBudget

    /// Whether the campaign duration is unlimited.
    ///
    public let isEvergreen: Bool

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
    public let targeting: BlazeTargetOptions?

    /// Sample format `urn:wpcom:post:123456:789`
    /// - 123456 is the site ID
    /// - 789 is the product ID
    ///
    public let targetUrn: String

    /// Accepted options - post, page, product
    ///
    public let type: String

    public init(origin: String,
                originVersion: String,
                paymentMethodID: String,
                startDate: Date,
                endDate: Date,
                timeZone: String,
                budget: BlazeCampaignBudget,
                isEvergreen: Bool,
                siteName: String,
                textSnippet: String,
                targetUrl: String,
                urlParams: String,
                mainImage: Image,
                targeting: BlazeTargetOptions?,
                targetUrn: String,
                type: String) {
        self.origin = origin
        self.originVersion = originVersion
        self.paymentMethodID = paymentMethodID
        self.startDate = startDate
        self.endDate = endDate
        self.timeZone = timeZone
        self.budget = budget
        self.isEvergreen = isEvergreen
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
