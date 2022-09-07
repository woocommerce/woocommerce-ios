import Foundation
import protocol Networking.Network

/// Defines actions supported by `JetpackConnectionStore`.
public enum JetpackConnectionAction: Action {
    /// Updates the store remote with the input siteURL and network to handle cookie authentication.
    /// Call this before triggering any other case in this action.
    case updateRemote(siteURL: String, network: Network)
    /// Fetches the URL used for setting up Jetpack connection.
    case fetchJetpackConnectionURL(completion: (Result<URL, Error>) -> Void)
    /// Fetches the user connection state with the given site's Jetpack.
    case fetchJetpackUser(completion: (Result<JetpackUser, Error>) -> Void)
}
