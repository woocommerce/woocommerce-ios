import Foundation
import Networking

// MARK: - GoogleAdsAction: Defines all of the Actions supported by the GoogleAdsStore.
//
public enum GoogleAdsAction: Action {

    /// Checks for connection of the given site with the Google Listings & Ads plugin.
    ///
    /// - `siteID`: the site to check the connection for.
    /// - `onCompletion`: invoked when the check request finishes.
    ///     - `result.success(GoogleAdsConnection)`: Successfully fetched the connection details.
    ///     - `result.failure(Error)`: error indicates issues fetching the connection details.
    ///
    case checkConnection(siteID: Int64,
                         onCompletion: (Result<GoogleAdsConnection, Error>) -> Void)

    /// Fetches Google ads campaigns for a given site.
    ///
    /// - `siteID`: the site to fetch campaigns for.
    /// - `onCompletion`: invoked when the fetch request finishes.
    ///     - `result.success([GoogleAdsCampaign])`: Successfully fetched campaigns.
    ///     - `result.failure(Error)`: error indicates issues fetching campaigns.
    ///
    case fetchAdsCampaigns(siteID: Int64,
                           onCompletion: (Result<[GoogleAdsCampaign], Error>) -> Void)

    /// Retrieves the Google ads paid campaign stats for the provided siteID, and time range, without saving them to the Storage layer.
    ///
    /// - Parameters:
    ///   - siteID: The site ID.
    ///   - campaignIDs: IDs of the ads campaigns to limit the stats results to.
    ///   - timeZone: The time zone to set the earliest/latest date strings in the API request.
    ///   - earliestDateToInclude: The earliest date to include in the results.
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - onCompletion: Invoked when the request finishes.
    ///     - `result.success(GoogleAdsCampaignStats)`: Successfully retrieved campaign stats.
    ///     - `result.failure(Error)`: Error indicates issues retrieving campaign stats.
    case retrieveCampaignStats(siteID: Int64,
                               campaignIDs: [Int64] = [],
                               timeZone: TimeZone,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               onCompletion: (Result<GoogleAdsCampaignStats, Error>) -> Void)
}
