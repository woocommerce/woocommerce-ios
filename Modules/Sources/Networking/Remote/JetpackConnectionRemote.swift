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

    /// Fetches the connection state with the site's Jetpack for the authenticated user.
    ///
    public func fetchJetpackConnectionData(completion: @escaping (Result<JetpackConnectionData, Error>) -> Void) {
        let request = RESTRequest(siteURL: siteURL, method: .get, path: Path.jetpackConnectionData)
        let mapper = JetpackConnectionDataMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Establishes a site-level connection between the site and WordPress.com using Jetpack.
    /// Returns WPCom `blogID` of the connected site.
    ///
    public func registerSite() async throws -> Int64 {
        let request = RESTRequest(siteURL: siteURL, method: .post, path: Path.jetpackConnectionRegister)
        let mapper = JetpackConnectionRegistrationMapper()
        let authorizationURL = try await enqueue(request, mapper: mapper).authorizeUrl
        guard let components = URLComponents(string: authorizationURL),
              let blogID = components.queryItems?.first(where: { $0.name == Constants.clientID })?.value as? String,
              let numericID = Int64(blogID) else {
            throw ConnectionError.invalidAuthorizationURL
        }
        return numericID
    }

    /// Provisions the connection between the site and WordPress.com using Jetpack.
    /// Returns a response containing scope and secret to be sent for finalizing the connection.
    ///
    public func provisionConnection() async throws -> JetpackConnectionProvisionResponse {
        let request = RESTRequest(siteURL: siteURL, method: .post, path: Path.jetpackConnectionProvision)
        let mapper = JetpackConnectionProvisionMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Finalizes the connection by sending a request to WPCom.
    ///
    public func finalizeConnection(siteID: Int64, provisionResponse: JetpackConnectionProvisionResponse) async throws {
        let parameters: [String: Any] = [
            Parameters.secret: provisionResponse.secret,
            Parameters.scope: provisionResponse.scope,
            Parameters.externalUserID: provisionResponse.userId,
            Parameters.redirectURI: siteURL
        ]
        let request = JetpackRequest(wooApiVersion: .mark2,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.wpcomConnection,
                                     parameters: parameters,
                                     availableAsRESTRequest: false)
        return try await enqueue(request)
    }
}

public extension JetpackConnectionRemote {
    enum ConnectionError: Int, Error {
        case malformedURL
        case accountConnectionURLNotFound
        case invalidAuthorizationURL
    }
}

private extension JetpackConnectionRemote {
    enum Path {
        static let jetpackConnectionURL = "/jetpack/v4/connection/url"
        static let jetpackConnectionData = "/jetpack/v4/connection/data"
        static let jetpackConnectionRegister = "/jetpack/v4/connection/register"
        static let jetpackConnectionProvision = "/jetpack/v4/remote_provision"
        static let wpcomConnection = "jetpack-remote-connect-user"
        static let plugins = "/wp/v2/plugins"
        static let jetpackModule = "/jetpack/v4/module"
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
        static let clientID = "client_id"
    }

    enum Parameters {
        static let secret = "secret"
        static let externalUserID = "external_user_id"
        static let redirectURI = "redirect_uri"
        static let scope = "scope"
    }
}
