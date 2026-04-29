import Foundation
import enum NetworkingCore.JetpackConnectionError
import struct NetworkingCore.JetpackConnectionProvisionMapper
import enum NetworkingCore.WooConstants

/// Handle API requests to the Jetpack REST API.
///
public final class JetpackConnectionRemote: Remote {
    private let siteURL: String
    private let network: Network
    private var accountConnectionURL: URL?

    public init(siteURL: String, network: Network) {
        self.siteURL = siteURL
        self.network = network
        super.init(network: network)
    }

    /// Retrieves the information about Jetpack the plugin for the current site.
    ///
    public func retrieveJetpackPluginDetails(siteID: Int64, completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        let path = "\(Path.plugins)/\(Constants.jetpackPluginName)"
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: siteID, path: path, availableAsRESTRequest: true)
        let mapper = SitePluginMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Installs Jetpack the plugin to the current site.
    ///
    public func installJetpackPlugin(siteID: Int64, completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        let parameters: [String: Any] = [Field.slug.rawValue: Constants.jetpackPluginSlug]
        let request = JetpackRequest(wooApiVersion: .none, method: .post, siteID: siteID, path: Path.plugins, parameters: parameters, availableAsRESTRequest: true)
        let mapper = SitePluginMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Activates Jetpack the plugin to the current site
    ///
    public func activateJetpackPlugin(siteID: Int64, completion: @escaping (Result<SitePlugin, Error>) -> Void) {
        let path = "\(Path.plugins)/\(Constants.jetpackPluginName)"
        let parameters: [String: Any] = [Field.status.rawValue: Constants.activeStatus]
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
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

    /// Registers Jetpack site connection by requesting the input URL while disabling automatic redirection,
    /// and returns the URL in the requested redirection.
    /// To simplify redirection manipulation, we'll use a `URLSession` here instead of `Network`.
    ///
    public func registerJetpackSiteConnection(with url: URL, completion: @escaping (Result<URL, Error>) -> Void) {

        let configuration = URLSessionConfiguration.default
        for cookie in network.session.configuration.httpCookieStorage?.cookies ?? [] {
            configuration.httpCookieStorage?.setCookie(cookie)
        }

        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        do {
            let request = try URLRequest(url: url, method: .get)
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                if let result = self?.accountConnectionURL {
                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                    return
                }
                // We don't expect any response here since we'll cancel the task as soon as a redirect request is received.
                // So always complete with a failure here.
                let returnedError = error ?? JetpackConnectionError.accountConnectionURLNotFound
                DispatchQueue.main.async {
                    completion(.failure(returnedError))
                }
                return
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }

    /// Fetches the connection state with the site's Jetpack for the authenticated user.
    ///
    public func fetchJetpackConnectionData(siteID: Int64, completion: @escaping (Result<JetpackConnectionData, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: siteID, path: Path.jetpackConnectionData, availableAsRESTRequest: true)
        let mapper = JetpackConnectionDataMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Fetches the WP.com blog ID for the current Jetpack-connected site.
    ///
    public func fetchJetpackBlogID(siteID: Int64 = WooConstants.placeholderSiteID, completion: @escaping (Result<Int64, Error>) -> Void) {
        fetchJetpackConnectionData(siteID: siteID) { result in
            let mappedResult = result.flatMap { connectionData -> Result<Int64, Error> in
                guard let blogID = connectionData.blogID else {
                    return .failure(JetpackConnectionError.blogIDUnavailable)
                }
                return .success(blogID)
            }
            completion(mappedResult)
        }
    }

    /// Fetches the WP.com blog ID for the current Jetpack-connected site.
    ///
    public func fetchJetpackBlogID(siteID: Int64 = WooConstants.placeholderSiteID) async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            fetchJetpackBlogID(siteID: siteID) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Establishes a site-level connection between the site and WordPress.com using Jetpack.
    /// Returns WPCom `blogID` of the connected site.
    /// periphery: ignore - used in `JetpackConnectionStore` later
    ///
    public func registerSite() async throws -> Int64 {
        let request = RESTRequest(siteURL: siteURL, method: .post, path: Path.jetpackConnectionRegister)
        let mapper = JetpackConnectionRegistrationMapper()
        let authorizationURL = try await enqueue(request, mapper: mapper).authorizeUrl
        guard let components = URLComponents(string: authorizationURL),
              let blogID = components.queryItems?.first(where: { $0.name == Constants.clientID })?.value as? String,
              let numericID = Int64(blogID) else {
            throw JetpackConnectionError.invalidAuthorizationURL
        }
        return numericID
    }

    /// Provisions the connection between the site and WordPress.com using Jetpack.
    /// Returns a response containing scope and secret to be sent for finalizing the connection.
    /// periphery: ignore - used in `JetpackConnectionStore` later
    ///
    public func provisionConnection() async throws -> JetpackConnectionProvisionResponse {
        let request = RESTRequest(siteURL: siteURL, method: .post, path: Path.jetpackConnectionProvision)
        let mapper = JetpackConnectionProvisionMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - URLSessionDataDelegate conformance
//
extension JetpackConnectionRemote: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest) async -> URLRequest? {
        // Disables redirection if the request is to load the Jetpack account connection URL
        if let url = request.url,
            url.absoluteString.hasPrefix(Constants.jetpackAccountConnectionURL) {
            accountConnectionURL = url
            task.cancel()
            return nil
        }
        return request
    }
}

private extension JetpackConnectionRemote {
    enum Path {
        static let jetpackConnectionURL = "/jetpack/v4/connection/url"
        static let jetpackConnectionData = "/jetpack/v4/connection/data"
        static let jetpackConnectionRegister = "/jetpack/v4/connection/register"
        static let jetpackConnectionProvision = "/jetpack/v4/remote_provision"
        static let plugins = "wp/v2/plugins"
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
}
