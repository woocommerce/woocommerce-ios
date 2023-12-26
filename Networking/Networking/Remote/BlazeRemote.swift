import Foundation

/// Protocol for `BlazeRemote` mainly used for mocking.
///
public protocol BlazeRemoteProtocol {
    /// Loads campaigns for the site with the provided ID on the given page number.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to load ads campaigns.
    ///    - pageNumber: the page number of campaign to load.
    ///
    func loadCampaigns(for siteID: Int64, pageNumber: Int) async throws -> [BlazeCampaign]

    /// Fetches target languages for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///
    func fetchTargetLanguages(for siteID: Int64) async throws -> [BlazeTargetLanguage]

    /// Fetches target devices for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///
    func fetchTargetDevices(for siteID: Int64) async throws -> [BlazeTargetDevice]

    /// Fetches target topics for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///
    func fetchTargetTopics(for siteID: Int64) async throws -> [BlazeTargetTopic]

    /// Fetches target locations for campaign creation.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to create ads campaigns.
    ///    - query: Keyword to search for locations.
    ///
    func fetchTargetLocations(for siteID: Int64, query: String) async throws -> [BlazeTargetLocation]
}

/// Blaze: Remote Endpoints
///
public final class BlazeRemote: Remote, BlazeRemoteProtocol {

    public func loadCampaigns(for siteID: Int64, pageNumber: Int) async throws -> [BlazeCampaign] {
        let path = Paths.campaignSearch(siteID: siteID)
        let parameters: [String: Any] = [
            Keys.page: pageNumber,
            Keys.orderBy: Values.postDate, // change this if we have other options for ordering
            Keys.order: Values.desc // change this if we have other options for ordering
        ]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeCampaignListMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target languages for campaign creation.
    ///
    public func fetchTargetLanguages(for siteID: Int64) async throws -> [BlazeTargetLanguage] {
        let path = BlazeTargetOption.languages.path(for: siteID)
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path)
        let mapper = BlazeTargetLanguageListMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target devices for campaign creation.
    ///
    public func fetchTargetDevices(for siteID: Int64) async throws -> [BlazeTargetDevice] {
        let path = BlazeTargetOption.devices.path(for: siteID)
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path)
        let mapper = BlazeTargetDeviceListMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target topics for campaign creation.
    ///
    public func fetchTargetTopics(for siteID: Int64) async throws -> [BlazeTargetTopic] {
        let path = BlazeTargetOption.topics.path(for: siteID)
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path)
        let mapper = BlazeTargetTopicListMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches target locations for campaign creation.
    ///
    public func fetchTargetLocations(for siteID: Int64, query: String) async throws -> [BlazeTargetLocation] {
        let path = BlazeTargetOption.locations(query: query).path(for: siteID)
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path)
        let mapper = BlazeTargetLocationListMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

private extension BlazeRemote {
    enum BlazeTargetOption {
        case languages
        case devices
        case topics
        case locations(query: String)

        // TODO-11512: Revise the paths when the API is finalized.
        func path(for siteID: Int64) -> String {
            let suffix: String = {
                switch self {
                case .languages:
                    return "languages"
                case .devices:
                    return "devices"
                case .topics:
                    return "page-topics"
                case .locations(let query):
                    return "locations?query=" + query
                }
            }()
            return "sites/\(siteID)/wordads/dsp/api/v1.1/targeting/" + suffix
        }
    }

    enum Paths {
        static func campaignSearch(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1/search/campaigns/site/\(siteID)"
        }
    }

    enum Keys {
        static let orderBy = "order_by"
        static let order =  "order"
        static let page = "page"
    }

    enum Values {
        static let postDate = "post_date"
        static let desc = "desc"
    }
}
