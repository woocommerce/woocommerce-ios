import Foundation
import WordPressAuthenticator

/// An interface used for mocking `WordPressAuthenticator` in unit tests.
/// It's not complete for now since this is used for testing `WrongAccountErrorViewModel` only at the time of writing.
/// Update this further if necessary.
///
protocol Authenticator {
    /// Used to present the site credential login flow directly from the delegate.
    ///
    /// - Parameters:
    ///     - presenter: The view controller that presents the site credential login flow.
    ///     - siteURL: The URL of the site to log in to.
    ///     - onCompletion: The closure to be trigged when the login succeeds with the input credentials.
    ///
    static func showSiteCredentialLogin(from presenter: UIViewController, siteURL: String, onCompletion: @escaping (WordPressOrgCredentials) -> Void)

    /// A helper method to fetch site info for a given URL.
    /// - Parameters:
    ///     - siteURL: The URL of the site to fetch information for.
    ///     - onCompletion: The closure to be triggered when fetching site info is done.
    ///
    static func fetchSiteInfo(for siteURL: String, onCompletion: @escaping (Result<WordPressComSiteInfo, Error>) -> Void)
}

/// Makes `WordPressAuthenticator` conform to the interface for mocking.
///
extension WordPressAuthenticator: Authenticator {}
