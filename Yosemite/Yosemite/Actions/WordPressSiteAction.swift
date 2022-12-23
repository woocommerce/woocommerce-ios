import Foundation

/// WordPressSiteAction: Defines all of the Actions supported by the WordPressSiteStore.
///
public enum WordPressSiteAction: Action {
    /// Fetches information for a given WordPress site URL.
    case fetchSiteInfo(siteURL: String, completion: (Result<Site, Error>) -> Void)
}
