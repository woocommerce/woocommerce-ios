import Foundation

/// Handle API requests to the Jetpack REST API.
///
public final class JetpackConnectionRemote: Remote {
    private let siteURL: String

    private var accountConnectionURL: URL?

    public init(siteURL: String, network: Network) {
        self.siteURL = siteURL
        super.init(network: network)
    }

    /// Retrieves the information about Jetpack the plugin for the current site.
    ///
    public func retrieveJetpackPluginDetails(completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        let path = "\(Path.plugins)/\(Constants.jetpackPluginName)"
        let request = RESTRequest(siteURL: siteURL, method: .get, path: path)
        let mapper = SitePluginMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Installs Jetpack the plugin to the current site.
    ///
    public func installJetpackPlugin(completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        let parameters: [String: Any] = [Field.slug.rawValue: Constants.jetpackPluginSlug]
        let request = RESTRequest(siteURL: siteURL, method: .post, path: Path.plugins, parameters: parameters)
        let mapper = SitePluginMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Activates Jetpack the plugin to the current site
    ///
    public func activateJetpackPlugin(completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        let path = "\(Path.plugins)/\(Constants.jetpackPluginName)"
        let parameters: [String: Any] = [Field.status.rawValue: Constants.activeStatus]
        let request = RESTRequest(siteURL: siteURL, method: .put, path: path, parameters: parameters)
        let mapper = SitePluginMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Fetches the URL for setting up Jetpack connection.
    ///
    public func fetchJetpackConnectionURL(completion: @escaping (Result<URL, Error>) -> Void) {
        let request = RESTRequest(siteURL: siteURL, method: .get, path: Path.jetpackConnectionURL)
        let mapper = JetpackConnectionURLMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Fetches the user connection state with the site's Jetpack.
    ///
    public func fetchJetpackUser(completion: @escaping (Result<JetpackUser, Error>) -> Void) {
        let request = RESTRequest(siteURL: siteURL, method: .get, path: Path.jetpackConnectionUser)
        let mapper = JetpackUserMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}

public extension JetpackConnectionRemote {
    enum ConnectionError: Int, Error {
        case malformedURL
        case accountConnectionURLNotFound
    }
}

private extension JetpackConnectionRemote {
    enum Path {
        static let jetpackConnectionURL = "/jetpack/v4/connection/url"
        static let jetpackConnectionUser = "/jetpack/v4/connection/data"
        static let plugins = "/wp/v2/plugins"
    }

    enum Field: String {
        case slug
        case status
    }

    enum Constants {
        static let jetpackAccountConnectionURL = "https://jetpack.wordpress.com/jetpack.authorize"
        static let jetpackPluginName = "jetpack/jetpack"
        static let jetpackPluginSlug = "jetpack"
        static let activeStatus = "active"
    }
}
