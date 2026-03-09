import Foundation

/// Discovers the WordPress REST API root URL for a given site by performing a HEAD request
/// and parsing the `Link` response header per the WordPress REST API discovery specification.
///
/// Concurrent requests for the same site URL are deduplicated — only one HEAD request is
/// made in-flight at a time per site, and subsequent callers share the result.
///
/// See: https://developer.wordpress.org/rest-api/using-the-rest-api/discovery/
///
public struct WordPressAPIDiscovery {
    private let session: URLSessionProtocol
    private let cache: WordPressRESTAPIRootCache

    /// Shared coordinator that deduplicates in-flight discovery requests.
    private static let coordinator = DiscoveryCoordinator()

    public init(session: URLSessionProtocol = URLSession.shared,
                cache: WordPressRESTAPIRootCache = .shared) {
        self.session = session
        self.cache = cache
    }

    /// Discovers the REST API root URL by sending a HEAD request to the given site URL.
    ///
    /// - Parameter siteURL: The site URL to discover the REST API root for.
    /// - Returns: The discovered REST API root URL string, or `nil` if discovery fails.
    ///
    public func discoverRESTAPIRootURL(for siteURL: String) async -> String? {
        await Self.coordinator.discover(siteURL: siteURL, session: session, cache: cache)
    }
}

/// Actor that deduplicates in-flight REST API discovery requests.
///
/// When multiple callers request discovery for the same site URL concurrently,
/// only one HEAD request is performed and all callers receive the same result.
///
private actor DiscoveryCoordinator {
    private var inFlight: [String: Task<String?, Never>] = [:]

    func discover(siteURL: String, session: URLSessionProtocol, cache: WordPressRESTAPIRootCache) async -> String? {
        let key = siteURL.trimSlashes().lowercased()

        // Return existing in-flight task if one exists
        if let existing = inFlight[key] {
            return await existing.value
        }

        let task = Task<String?, Never> {
            guard let url = URL(string: siteURL) else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            do {
                let (_, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { return nil }
                guard let root = DiscoveryCoordinator.parseRESTAPIRootURL(from: httpResponse) else { return nil }
                cache.setRoot(root, for: siteURL)
                return root
            } catch {
                DDLogDebug("⚠️ REST API discovery failed for \(siteURL): \(error)")
                return nil
            }
        }

        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        return result
    }

    /// Parses the REST API root URL from the `Link` header of an HTTP response.
    ///
    /// The expected header format is:
    /// ```
    /// Link: <https://example.com/wp-json/>; rel="https://api.w.org/"
    /// ```
    ///
    static func parseRESTAPIRootURL(from response: HTTPURLResponse) -> String? {
        guard let linkHeader = response.value(forHTTPHeaderField: "Link") else { return nil }

        // The Link header may contain multiple link relations separated by commas.
        let links = linkHeader.components(separatedBy: ",")
        for link in links {
            let parts = link.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 2 else { continue }

            let urlPart = parts[0]
            let hasAPIRel = parts.dropFirst().contains(where: { $0.contains("https://api.w.org/") })
            guard hasAPIRel else { continue }

            // Extract the URL from angle brackets: <URL>
            guard urlPart.hasPrefix("<"), urlPart.hasSuffix(">") else { continue }
            return String(urlPart.dropFirst().dropLast())
        }
        return nil
    }
}
