import Foundation
import Networking

// MARK: - DeauthenticatedUserAction: Defines all of the actions supported by the DeauthenticatedUserStore
//
public enum DeauthenticatedUserAction: Action {
    /// Updates the store remote with the input network to handle cookie authentication.
    /// Call this before triggering any other case in this action.
    case authenticate(network: Network)

    /// Retrieves user information for the logged in user from the given site.
    ///
    case retrieveUser(siteURL: String, onCompletion: (Result<User, Error>) -> Void)
}
