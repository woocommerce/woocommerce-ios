import Foundation
import WordPressKit

/// Defines actions supported by `JetpackConnectionStore`.
public enum JetpackConnectionAction: Action {
    /// Fetches the URL used for setting up Jetpack connection using the given authenticator
    case fetchJetpackConnectionURL(siteURL: String, authenticator: Authenticator, completion: (Result<URL?, Error>) -> Void)
}
