import Foundation
import Networking

// MARK: - UserAction: Defines all of the actions supported by the UserStore
//
public enum UserAction: Action {
    /// Retrieves user information from a specific dotcom or self-hosted site.
    ///
    /// The account must be connected to a dotcom account. Additionally, for self-hosted
    /// sites, it *must* be connected to dotcom via Jetpack.
    ///
    case retrieveUser(siteID: Int64, onCompletion: (Result<User, Error>) -> Void)

    /// Fetches the user IP's country code. Uses the WordPress public API..
    ///
    case fetchUserIPCountryCode(onCompletion: (Result<String, Error>) -> Void)
}
