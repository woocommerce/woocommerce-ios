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
}
