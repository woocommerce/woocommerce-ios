import Foundation
import Networking
import WordPressKit

/// Defines actions supported by `JetpackConnectionStore`.
public enum JetpackConnectionAction: Action {
    /// Fetches the URL used for setting up Jetpack connection.
    case fetchJetpackConnectionURL(completion: (Result<URL, Error>) -> Void)
    /// Fetches the user connection state with the given site's Jetpack.
    case fetchJetpackUser(completion: (Result<JetpackUser, Error>) -> Void)
}
