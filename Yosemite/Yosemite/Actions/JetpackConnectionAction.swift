import Foundation
import protocol Networking.Network

/// Defines actions supported by `JetpackConnectionStore`.
public enum JetpackConnectionAction: Action {
    /// Updates the store remote with the input siteURL and network to handle cookie authentication.
    /// Call this before triggering any other case in this action.
    case authenticate(siteURL: String, network: Network)
    /// Retrieves details about Jetpack plugin for the current site.
    case retrieveJetpackPluginDetails(completion: (Result<SitePlugin, Error>) -> Void)
    /// Installs Jetpack the plugin for the current site.
    case installJetpackPlugin(completion: (Result<Void, Error>) -> Void)
    /// Updates Jetpack the plugin for the current site.
    case activateJetpackPlugin(completion: (Result<Void, Error>) -> Void)
    /// Fetches the URL used for setting up Jetpack connection.
    case fetchJetpackConnectionURL(completion: (Result<URL, Error>) -> Void)
    /// Fetches the user connection state with the given site's Jetpack.
    case fetchJetpackUser(completion: (Result<JetpackUser, Error>) -> Void)
    /// Fetches the WPCom account with the given network
    case loadWPComAccount(network: Network, onCompletion: (Account?) -> Void)
}
