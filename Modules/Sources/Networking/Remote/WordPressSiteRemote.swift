import Foundation
import NetworkingCore

/// Endpoints for WordPress site information.
///
public final class WordPressSiteRemote: Remote {

    private let apiRootCache: RESTAPIRootCaching
    private let discoverRESTAPIRoot: (String) async -> String?

    override public init(network: Network) {
        self.apiRootCache = WordPressRESTAPIRootCache.shared
        let discovery = WordPressAPIDiscovery()
        self.discoverRESTAPIRoot = { siteURL in
            await discovery.resolveRESTAPIRootURL(for: siteURL)
        }
        super.init(network: network)
    }

    init(network: Network,
         apiRootCache: RESTAPIRootCaching,
         discoverRESTAPIRoot: @escaping (String) async -> String?) {
        self.apiRootCache = apiRootCache
        self.discoverRESTAPIRoot = discoverRESTAPIRoot
        super.init(network: network)
    }

    /// Fetches info for a WordPress site given its URL.
    ///
    public func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        let cachedRoot = apiRootCache.root(for: siteURL)
        let root = await resolvedRESTAPIRoot(for: siteURL)
        do {
            return try await fetchSiteInfo(at: root)
        } catch {
            guard cachedRoot == root else {
                throw error
            }

            apiRootCache.removeRoot(root, for: siteURL)
            guard let replacementRoot = await discoverRESTAPIRoot(siteURL),
                  replacementRoot != root else {
                throw error
            }
            return try await fetchSiteInfo(at: replacementRoot)
        }
    }

    /// Fetches the page list for a WordPress site given its URL.
    ///
    public func fetchSitePages(for siteURL: String) async throws -> [WordPressPage] {
        let url = try await resolvedSitePagesURL(for: siteURL)
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressPageListMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

private extension WordPressSiteRemote {
    func fetchSiteInfo(at root: String) async throws -> WordPressSite {
        guard let url = URL(string: root) else {
            throw NetworkError.invalidURL
        }
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressSiteMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Returns the URL for the pages endpoint, using the discovered REST API root when available.
    ///
    func resolvedSitePagesURL(for siteURL: String) async throws -> URL {
        let root = await resolvedRESTAPIRoot(for: siteURL)
        guard let url = URL(string: root + Path.pages) else {
            throw NetworkError.invalidURL
        }
        return url
    }

    func resolvedRESTAPIRoot(for siteURL: String) async -> String {
        if let cachedRoot = apiRootCache.root(for: siteURL) {
            return cachedRoot
        }
        return await discoverRESTAPIRoot(siteURL) ?? WordPressAPIDiscovery.defaultRESTAPIRootURL(for: siteURL)
    }
}

private extension WordPressSiteRemote {
    enum Path {
        static let pages = "wp/v2/pages?_fields=id,title,link"
    }
}
