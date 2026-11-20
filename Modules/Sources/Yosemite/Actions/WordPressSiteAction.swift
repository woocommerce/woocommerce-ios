import Foundation

/// WordPressSiteAction: Defines all of the Actions supported by the WordPressSiteStore.
///
public enum WordPressSiteAction: Action {
    /// Fetches information for a given WordPress site URL.
    case fetchSiteInfo(siteURL: String, detectUnexpectedResponses: Bool = false, completion: @Sendable (Result<Site, Error>) -> Void)
    /// Fetches application password authorization URL for a given WordPress site if it's enabled.
    /// Fails with `ApplicationPasswordAuthorizationError.siteMismatch` when the approval page belongs to another site.
    case fetchApplicationPasswordAuthorizationURL(siteURL: String,
                                                  detectUnexpectedResponses: Bool = false,
                                                  completion: @Sendable (Result<ApplicationPasswordAuthorization?, Error>) -> Void)
    case fetchPageList(siteURL: String, completion: @Sendable (Result<[WordPressPage], Error>) -> Void)
}
