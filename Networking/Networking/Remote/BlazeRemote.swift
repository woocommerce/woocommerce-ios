import Codegen
import Foundation
import struct Alamofire.JSONEncoding

/// Protocol for `BlazeRemote` mainly used for mocking.
///
public protocol BlazeRemoteProtocol {
    /// Creates a new Blaze campaign
    /// - Parameters:
    ///    - campaign: Details of the Blaze campaign to be created
    ///    - siteID: WPCom ID for the site to create the campaign in.
    ///
    func createCampaign(_ campaign: CreateBlazeCampaign,
                        siteID: Int64) async throws

    /// Loads list campaign info for the site with the provided ID
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to load ads campaigns.
    ///    - skip: Pagination offset
    ///    - limit: Pagination limit
    ///
    func loadCampaignsList(for siteID: Int64,
                            skip: Int,
                            limit: Int) async throws -> [BlazeCampaignListItem]

    /// Fetches target languages for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///    - locale: The locale to receive in the response.
    ///
    func fetchTargetLanguages(for siteID: Int64, locale: String) async throws -> [BlazeTargetLanguage]

    /// Fetches target devices for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///    - locale: The locale to receive in the response.
    ///
    func fetchTargetDevices(for siteID: Int64, locale: String) async throws -> [BlazeTargetDevice]

    /// Fetches target topics for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///    - locale: The locale to receive in the response.
    ///
    func fetchTargetTopics(for siteID: Int64, locale: String) async throws -> [BlazeTargetTopic]

    /// Fetches target locations for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///    - query: Keyword to search for locations. Requires a minimum of 3 characters, or else will return error.
    ///    - locale: The locale to receive in the response.
    ///
    func fetchTargetLocations(for siteID: Int64, query: String, locale: String) async throws -> [BlazeTargetLocation]

    /// Fetches forecasted campaign impressions.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///    - input: BlazeForecastedImpressionsInput object containing various parameters for the request.
    ///
    func fetchForecastedImpressions(
        for siteID: Int64,
        with input: BlazeForecastedImpressionsInput
    ) async throws -> BlazeImpressions

    /// Fetches AI based suggestions for Blaze campaign tagline and description for given product ID
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create the campaign in.
    ///    - productID: ID of the product to create the campaign for.
    ///
    func fetchAISuggestions(siteID: Int64,
                            productID: Int64) async throws -> [BlazeAISuggestion]

    /// Fetches payment info for creating Blaze campaigns given a site ID.
    /// - Parameter siteID: ID of the site to create Blaze campaigns for.
    ///
    func fetchPaymentInfo(siteID: Int64) async throws -> BlazePaymentInfo

    /// Fetches objectives for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///    - locale: The locale to receive in the response.
    ///
    func fetchCampaignObjectives(siteID: Int64, locale: String) async throws -> [BlazeCampaignObjective]
}

/// Blaze: Remote Endpoints
///
public final class BlazeRemote: Remote, BlazeRemoteProtocol {

    public func createCampaign(_ campaign: CreateBlazeCampaign,
                               siteID: Int64) async throws {
        let path = Paths.campaigns(siteID: siteID)

        let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
        let parameters = try campaign.toDictionary(keyEncodingStrategy: .convertToSnakeCase, dateFormatter: dateFormatter)
            .compactMapValues { $0 } // filters out any field with nil value


        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: path,
                                    parameters: parameters,
                                    encoding: JSONEncoding.default)
        let mapper = CreateBlazeCampaignMapper()
        try await enqueue(request, mapper: mapper)
    }

    /// Loads list of Blaze campaigns.
    ///
    public func loadCampaignsList(for siteID: Int64,
                                   skip: Int,
                                   limit: Int) async throws -> [BlazeCampaignListItem] {
        let path = Paths.campaigns(siteID: siteID)
        let parameters: [String: Any] = [
            Keys.LoadCampaigns.siteID: siteID,
            Keys.LoadCampaigns.skip: skip,
            Keys.LoadCampaigns.limit: limit
        ]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeCampaignListItemsMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target languages for campaign creation.
    ///
    public func fetchTargetLanguages(for siteID: Int64, locale: String) async throws -> [BlazeTargetLanguage] {
        let path = BlazeTargetOption.languages.endpoint(for: siteID)
        let parameters: [String: Any] = [Keys.locale: locale]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeTargetLanguageListMapper(locale: locale)
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target devices for campaign creation.
    ///
    public func fetchTargetDevices(for siteID: Int64, locale: String) async throws -> [BlazeTargetDevice] {
        let path = BlazeTargetOption.devices.endpoint(for: siteID)
        let parameters: [String: Any] = [Keys.locale: locale]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeTargetDeviceListMapper(locale: locale)
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target topics for campaign creation.
    ///
    public func fetchTargetTopics(for siteID: Int64, locale: String) async throws -> [BlazeTargetTopic] {
        let path = BlazeTargetOption.topics.endpoint(for: siteID)
        let parameters: [String: Any] = [Keys.locale: locale]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeTargetTopicListMapper(locale: locale)
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target locations for campaign creation.
    ///
    public func fetchTargetLocations(for siteID: Int64, query: String, locale: String) async throws -> [BlazeTargetLocation] {
        let path = BlazeTargetOption.locations.endpoint(for: siteID)
        let parameters: [String: Any] = [
            Keys.locale: locale,
            Keys.query: query
        ]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeTargetLocationListMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches forecasted campaign impressions.
    ///
    public func fetchForecastedImpressions(
        for siteID: Int64,
        with input: BlazeForecastedImpressionsInput
    ) async throws -> BlazeImpressions {
        let path = Paths.campaignImpressions(siteID: siteID)

        let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
        dateFormatter.dateFormat = Constants.dateFormat

        let parameters = try input.toDictionary(keyEncodingStrategy: .convertToSnakeCase, dateFormatter: dateFormatter)
            .compactMapValues { $0 } // filters out any field with nil value

        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: path,
                                    parameters: parameters,
                                    encoding: JSONEncoding.default)
        let mapper = BlazeImpressionsMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches AI based suggestions for Blaze campaign tagline and description for given product ID
    ///
    public func fetchAISuggestions(siteID: Int64,
                                   productID: Int64) async throws -> [BlazeAISuggestion] {
        let path = Paths.aiSuggestions(siteID: siteID)

        /// Expected format:
        /// {
        ///     "urn": "urn:wpcom:post:<site_id>:<product_id>"
        /// }
        ///
        let parameters = [Keys.AISuggestions.urn: "\(Keys.AISuggestions.urn):\(Keys.AISuggestions.wpcom):\(Keys.AISuggestions.post):\(siteID):\(productID)"]

        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path, parameters: parameters, encoding: JSONEncoding.default)
        let mapper = BlazeAISuggestionListMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches payment info for creating Blaze campaigns given a site ID.
    ///
    public func fetchPaymentInfo(siteID: Int64) async throws -> BlazePaymentInfo {
        let path = Paths.paymentInfo(siteID: siteID)
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path)
        let mapper = BlazePaymentInfoMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches objectives for campaign creation.
    ///
    public func fetchCampaignObjectives(siteID: Int64, locale: String) async throws -> [BlazeCampaignObjective] {
        let path = Paths.campaignObjective(siteID: siteID)
        let parameters: [String: Any] = [Keys.locale: locale]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeCampaignObjectiveListMapper(locale: locale)
        return try await enqueue(request, mapper: mapper)
    }
}

private extension BlazeRemote {
    enum BlazeTargetOption {
        case languages
        case devices
        case topics
        case locations

        // TODO-11512: Revise the paths when the API is finalized.
        func endpoint(for siteID: Int64) -> String {
            let suffix: String = {
                switch self {
                case .languages:
                    return "languages"
                case .devices:
                    return "devices"
                case .topics:
                    return "page-topics"
                case .locations:
                    return "locations"
                }
            }()
            return "sites/\(siteID)/wordads/dsp/api/v1.1/targeting/" + suffix
        }
    }

    enum Paths {
        static func campaigns(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1.1/campaigns"
        }

        static func campaignSearch(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1/search/campaigns/site/\(siteID)"
        }

        static func campaignImpressions(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1.1/forecast"
        }

        static func aiSuggestions(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1.1/suggestions"
        }

        static func paymentInfo(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1.1/payment-methods"
        }

        static func campaignObjective(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1.1/campaigns/objectives"
        }
    }

    enum Keys {
        static let orderBy = "order_by"
        static let order =  "order"
        static let page = "page"
        static let query = "query"
        static let locale = "locale"
        enum AISuggestions {
            static let urn = "urn"
            static let wpcom = "wpcom"
            static let post = "post"
        }


        enum LoadCampaigns {
            static let siteID = "site_id"
            static let skip = "skip"
            static let limit = "limit"
        }
    }

    enum Values {
        static let postDate = "post_date"
        static let desc = "desc"
    }

    enum Constants {
        static let dateFormat = "yyyy-MM-dd"
    }
}

/// Blaze Forecasted Impressions input
public struct BlazeForecastedImpressionsInput: Encodable, GeneratedFakeable {
    // Start date of the campaign.
    public let startDate: Date
    // End date of the campaign
    public let endDate: Date
    // Time zone of the user
    public let timeZone: String
    // Total budget of the campaign
    public let totalBudget: Double
    // Target options for the campaign. Optional.
    public let targeting: BlazeTargetOptions?
    // Whether the campaign time is unlimited
    public let isEvergreen: Bool

    public init(startDate: Date,
                endDate: Date,
                timeZone: String,
                totalBudget: Double,
                targeting: BlazeTargetOptions? = nil,
                isEvergreen: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.timeZone = timeZone
        self.totalBudget = totalBudget
        self.targeting = targeting
        self.isEvergreen = isEvergreen
    }

    private enum CodingKeys: String, CodingKey {
        case startDate
        case endDate
        case timeZone
        case totalBudget
        case targeting
        case isEvergreen
    }
}

/// Blaze Forecasted Impressions sub-input related to targetings.
public struct BlazeTargetOptions: Encodable, GeneratedFakeable, GeneratedCopiable, Equatable {
    // Target location IDs for the campaign. Optional.
    public let locations: [Int64]?
    // Target languages for the campaign. Optional.
    public let languages: [String]?
    // Target devices for the campaign. Optional.
    public let devices: [String]?
    // Target topics for the campaign. Optional.
    public let pageTopics: [String]?

    public init(locations: [Int64]?,
                languages: [String]?,
                devices: [String]?,
                pageTopics: [String]?) {
        self.locations = locations
        self.languages = languages
        self.devices = devices
        self.pageTopics = pageTopics
    }

    private enum TargetingsKeys: String, CodingKey {
        case locations
        case languages
        case devices
        case pageTopics
    }
}
