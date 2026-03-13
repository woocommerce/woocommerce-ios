import Foundation
import protocol Networking.Network

/// Defines actions supported by `JetpackConnectionStore`.
public enum JetpackConnectionAction: Action {
    /// Updates the store remote with the input siteURL and network to handle cookie authentication.
    /// Call this before triggering any other case in this action.
    case authenticate(siteURL: String, siteID: Int64, network: Network)
    /// Retrieves details about Jetpack plugin for the current site.
    case retrieveJetpackPluginDetails(completion: (Result<SitePlugin, Error>) -> Void)
    /// Installs Jetpack the plugin for the current site.
    case installJetpackPlugin(completion: (Result<Void, Error>) -> Void)
    /// Updates Jetpack the plugin for the current site.
    case activateJetpackPlugin(completion: (Result<Void, Error>) -> Void)
    /// Fetches the URL used for setting up Jetpack connection.
    case fetchJetpackConnectionURL(authenticatedWithWPCom: Bool,
                                   completion: (Result<URL, Error>) -> Void)
    /// Fetches connection state with the given site's Jetpack.
    case fetchJetpackConnectionData(completion: (Result<JetpackConnectionData, Error>) -> Void)
    /// Establishes site-level connection and returns WordPress.com blog ID.
    case registerSite(completion: (Result<Int64, Error>) -> Void)
    /// Provisions connection and returns provision response with scope and secret.
    case provisionConnection(completion: (Result<JetpackConnectionProvisionResponse, Error>) -> Void)
    /// Finalizes the Jetpack connection by sending a request to WPCom.
    case finalizeConnection(siteID: Int64,
                            siteURL: String,
                            provisionResponse: JetpackConnectionProvisionResponse,
                            network: Network,
                            completion: (Result<Void, Error>) -> Void)
    /// Fetches the WPCom account with the given network
    case loadWPComAccount(network: Network, onCompletion: (Account?) -> Void)
}
