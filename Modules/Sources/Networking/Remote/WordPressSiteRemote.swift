import Foundation
import NetworkingCore

/// Endpoints for WordPress site information.
///
public final class WordPressSiteRemote: Remote {

    private let apiRootCache: RESTAPIRootCaching

    override public init(network: Network) {
        self.apiRootCache = WordPressRESTAPIRootCache.shared
        super.init(network: network)
    }

    init(network: Network, apiRootCache: RESTAPIRootCaching) {
        self.apiRootCache = apiRootCache
        super.init(network: network)
    }

    /// Fetches info for a WordPress site given its URL.
    ///
    public func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        let url = try resolvedSiteInfoURL(for: siteURL)
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressSiteMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Fetches the page list for a WordPress site given its URL.
    ///
    public func fetchSitePages(for siteURL: String) async throws -> [WordPressPage] {
        let url = try resolvedSitePagesURL(for: siteURL)
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressPageListMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

private extension WordPressSiteRemote {
    /// Returns the URL for the site info endpoint, using the discovered REST API root when available.
    ///
    func resolvedSiteInfoURL(for siteURL: String) throws -> URL {
        if let root = apiRootCache.root(for: siteURL),
           let url = URL(string: root) {
            return url
        }
        guard let url = URL(string: siteURL + Path.root) else {
            throw NetworkError.invalidURL
        }
        return url
    }

    /// Returns the URL for the pages list endpoint, using the discovered REST API root when available.
    ///
    func resolvedSitePagesURL(for siteURL: String) throws -> URL {
        let root = apiRootCache.root(for: siteURL) ?? (siteURL + Path.root)
        guard let url = URL(string: root + Path.pages) else {
            throw NetworkError.invalidURL
        }
        return url
    }
}

private extension WordPressSiteRemote {
    enum Path {
        static let root = "?rest_route=/"
        static let pages = "wp/v2/pages?_fields=id,title,link"
    }
}
