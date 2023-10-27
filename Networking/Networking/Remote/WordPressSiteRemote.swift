import Foundation

/// Endpoints for WordPress site information.
///
public final class WordPressSiteRemote: Remote {

    private let session: URLSession

    public init(network: Network, session: URLSession = .shared) {
        self.session = session
        super.init(network: network)
    }

    /// Fetches information for a given site URL by hitting its root API endpoint.
    ///
    public func fetchSiteInfo(for siteURL: String) async throws -> WordPressSite {
        let path = Path.root
        guard let url = URL(string: siteURL + path) else {
            throw NetworkError.invalidURL
        }
        let request = try URLRequest(url: url, method: .get)
        let mapper = WordPressSiteMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Finds root API endpoint for a given site URL.
    /// Ref: https://developer.wordpress.org/rest-api/using-the-rest-api/discovery/
    ///
    public func findRootAPIEndpoint(for siteURL: String) async throws -> String {
        guard let url = URL(string: siteURL) else {
            throw NetworkError.invalidURL
        }
        let discoveryRequest = try URLRequest(url: url, method: .head)
        let (_, response) = try await session.data(for: discoveryRequest)
        let headers = (response as? HTTPURLResponse)?.allHeaderFields
        let rootLinkHeader = headers?.first(where: { header in
            (header.key as? String) == LinkHeader.title &&
            (header.value as? String)?.contains(LinkHeader.rel) == true
        })
        let rootLink = (rootLinkHeader?.value as? String)?
            .components(separatedBy: LinkHeader.separator)
            .first?
            .trimmingCharacters(in: .init(charactersIn: "<>"))
        return rootLink ?? String([siteURL, Path.root].joined(separator: "/"))
    }
}

private extension WordPressSiteRemote {
    enum Path {
        static let root = "wp-json"
    }
    enum LinkHeader {
        static let title = "Link"
        static let rel = "https://api.w.org/"
        static let separator = ";"
    }
}
