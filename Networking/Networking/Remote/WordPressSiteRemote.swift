import Foundation

/// Endpoints for WordPress site information.
///
public final class WordPressSiteRemote: Remote {
    public func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        let path = "/wp-json/"
        guard let url = URL(string: siteURL + path) else {
            throw NetworkError.invalidURL
        }
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressSiteMapper()
        return try await enqueue(request, mapper: mapper)
    }
}
