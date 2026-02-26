import Foundation
import NetworkingCore

/// Endpoints for WordPress site information.
///
public final class WordPressSiteRemote: Remote {

    private let apiRootCache: RESTAPIRootCaching

    public override init(network: Network) {
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
        if let root = apiRootCache.root(for: siteURL),
           let url = pagesURL(from: root) {
            return url
        }
        guard let url = URL(string: siteURL.trimSlashes() + Path.pages) else {
            throw NetworkError.invalidURL
        }
        return url
    }

    /// Builds the pages list URL from the given REST API root URL.
    ///
    /// Handles both permalink styles:
    /// - Pretty permalinks: `https://example.com/wp-json/` → `https://example.com/wp-json/wp/v2/pages?_fields=id,title,link`
    /// - Default permalinks: `https://example.com/?rest_route=/` → `https://example.com/?rest_route=/wp/v2/pages&_fields=id,title,link`
    ///
    /// Note: Uses `percentEncodedQueryItems` to preserve literal slashes and commas in the query values,
    /// matching the behavior of the WordPress REST API which expects unencoded slashes in `rest_route`.
    ///
    func pagesURL(from discoveredRoot: String) -> URL? {
        guard var components = URLComponents(string: discoveredRoot) else { return nil }

        if components.queryItems?.contains(where: { $0.name == "rest_route" }) == true {
            // ?rest_route=/ style: preserve unencoded slashes via percentEncodedQueryItems
            components.percentEncodedQueryItems = [
                URLQueryItem(name: "rest_route", value: "/wp/v2/pages"),
                URLQueryItem(name: "_fields", value: "id,title,link")
            ]
        } else {
            // wp-json/ style: append the pages path and set query parameters
            let basePath = components.path.hasSuffix("/") ? components.path : components.path + "/"
            components.path = basePath + "wp/v2/pages"
            // Preserve unencoded commas in the _fields value
            components.percentEncodedQueryItems = [URLQueryItem(name: "_fields", value: "id,title,link")]
        }
        return components.url
    }
}

private extension WordPressSiteRemote {
    enum Path {
        static let root = "/?rest_route=/"
        static let pages = "/?rest_route=/wp/v2/pages&_fields=id,title,link"
    }
}
