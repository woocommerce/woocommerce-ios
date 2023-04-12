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
                let returnedError = error ?? ConnectionError.accountConnectionURLNotFound
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

    /// Fetches the user connection state with the site's Jetpack.
    ///
    public func fetchJetpackUser(completion: @escaping (Result<JetpackUser, Error>) -> Void) {
        let request = RESTRequest(siteURL: siteURL, method: .get, path: Path.jetpackConnectionUser)
        let mapper = JetpackUserMapper()
        enqueue(request, mapper: mapper, completion: completion)
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
