import Foundation

/// WordPressSiteAction: Defines all of the Actions supported by the WordPressSiteStore.
///
public enum WordPressSiteAction: Action {
    /// Fetches information for a given WordPress site URL.
    case fetchSiteInfo(siteURL: String, completion: (Result<Site, Error>) -> Void)
    /// Fetches application password authorization URL for a given WordPress site if it's enabled.
    case fetchApplicationPasswordAuthorizationURL(siteURL: String, completion: (Result<URL?, Error>) -> Void)
}
