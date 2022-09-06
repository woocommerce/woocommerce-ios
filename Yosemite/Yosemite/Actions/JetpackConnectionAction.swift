import Foundation
import Networking
import WordPressKit

/// Defines actions supported by `JetpackConnectionStore`.
public enum JetpackConnectionAction: Action {
    /// Fetches the URL used for setting up Jetpack connection using the given authenticator
    case fetchJetpackConnectionURL(completion: (Result<URL, Error>) -> Void)
    /// Fetches the user connection state with the given site's Jetpack and authenticator.
    case fetchJetpackUser(completion: (Result<JetpackUser, Error>) -> Void)
}
