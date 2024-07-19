import Foundation

/// Interface for remote requests to Google Listings & Ads plugin.
///
public protocol GoogleListingsAndAdsRemoteProtocol {
    /// Check Google ads connection for the given site.
    ///
    func checkConnection(for siteID: Int64) async throws -> GoogleAdsConnection

    /// Fetch ads campaigns for the given site
    ///
    func fetchAdsCampaigns(for siteID: Int64) async throws -> [GoogleAdsCampaign]

    /// Fetch the paid campaign stats for the given site.
    ///
    /// - Parameters:
    ///   - siteID: The site ID.
    ///   - campaignIDs: IDs of the campaigns to filter the results by.
    ///   - timeZone: The time zone to set the earliest/latest date strings in the API request.
    ///   - earliestDateToInclude: The earliest date to include in the results.
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - totals: Optionally limit the stats totals to fetch. Defaults to all stats totals.
    ///   - orderby: Define the stats total to use for ordering the list of campaigns in the response.
    ///   - nextPageToken: Token to retrieve the next page of stats data.
    func loadCampaignStats(for siteID: Int64,
                           campaignIDs: [Int64],
                           timeZone: TimeZone,
                           earliestDateToInclude: Date,
                           latestDateToInclude: Date,
                           totals: [GoogleListingsAndAdsRemote.StatsField],
                           orderby: GoogleListingsAndAdsRemote.StatsField,
                           nextPageToken: String?) async throws -> GoogleAdsCampaignStats
}

/// Google Listings & Ads: Endpoints
///
public final class GoogleListingsAndAdsRemote: Remote, GoogleListingsAndAdsRemoteProtocol {

    public func checkConnection(for siteID: Int64) async throws -> GoogleAdsConnection {
        let path = Paths.connection
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        let mapper = GoogleAdsConnectionMapper()
        return try await enqueue(request, mapper: mapper)
    }

    public func fetchAdsCampaigns(for siteID: Int64) async throws -> [GoogleAdsCampaign] {
        let path = Paths.adsCampaigns
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        let mapper = GoogleAdsCampaignListMapper()
        return try await enqueue(request, mapper: mapper)
    }

    public func loadCampaignStats(for siteID: Int64,
                                  campaignIDs: [Int64],
                                  timeZone: TimeZone,
                                  earliestDateToInclude: Date,
                                  latestDateToInclude: Date,
                                  totals: [GoogleListingsAndAdsRemote.StatsField] = StatsField.allCases,
                                  orderby: GoogleListingsAndAdsRemote.StatsField,
                                  nextPageToken: String? = nil) async throws -> GoogleAdsCampaignStats {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = timeZone

        var parameters: [String: Any] = [
            ParameterKeys.after: dateFormatter.string(from: earliestDateToInclude),
            ParameterKeys.before: dateFormatter.string(from: latestDateToInclude),
            ParameterKeys.totals: totals.map { $0.rawValue }.joined(separator: ","),
            ParameterKeys.orderby: orderby.rawValue
        ]
        // Only include this parameter if the value is non-nil.
        parameters[ParameterKeys.nextPageToken] = nextPageToken

        // Only include `ids` parameter if the list is not empty.
        if campaignIDs.isEmpty == false {
            parameters[ParameterKeys.ids] = campaignIDs
        }

        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     path: Paths.campaignsReport,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = GoogleAdsCampaignStatsMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }
}

public extension GoogleListingsAndAdsRemote {
    /// Stats total fields for Google analytics reports
    ///
    enum StatsField: String, CaseIterable {
        case sales
        case spend
        case clicks
        case impressions
        case conversions
    }
}

private extension GoogleListingsAndAdsRemote {
    enum Paths {
        static let connection = "wc/gla/ads/connection"
        static let adsCampaigns = "wc/gla/ads/campaigns"
        static let campaignsReport = "wc/gla/ads/reports/programs"
    }

    enum ParameterKeys {
        static let after            = "after"
        static let before           = "before"
        static let totals           = "fields"
        static let orderby          = "orderby"
        static let nextPageToken    = "next_page"
        static let ids              = "ids"
    }
}
