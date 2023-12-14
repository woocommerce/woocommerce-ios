import Foundation

/// Endpoints for WordPress site information.
///
public final class WordPressSiteRemote: Remote {
    public func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        let path = Path.root
        guard let url = URL(string: siteURL + path) else {
            throw NetworkError.invalidURL
        }
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressSiteMapper()
        return try await enqueue(request, mapper: mapper)
    }

    public func fetchSitePages(for siteURL: String) async throws -> [WordPressPage] {
        let path = Path.pages
        guard let url = URL(string: siteURL.trimSlashes() + path) else {
            throw NetworkError.invalidURL
        }
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressPageListMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

private extension WordPressSiteRemote {
    enum Path {
        static let root = "/?rest_route=/"
        static let pages = "/?rest_route=/wp/v2/pages&_fields=id,title,link"
    }
}
