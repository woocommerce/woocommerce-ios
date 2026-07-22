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

    /// Returns the conventional WordPress REST API root used when discovery is unavailable.
    ///
    public static func defaultRESTAPIRootURL(for siteURL: String) -> String {
        siteURL.trimSlashes() + "/wp-json/"
    }

    /// Returns the query-style WordPress REST API root used by sites without pretty permalinks.
    ///
    public static func queryRESTAPIRootURL(for siteURL: String) -> String {
        siteURL.trimSlashes() + "/?rest_route=/"
    }

    /// Discovers the REST API root URL by sending a HEAD request to the given site URL.
    ///
    /// - Parameter siteURL: The site URL to discover the REST API root for.
    /// - Returns: The discovered REST API root URL string, or `nil` if discovery fails.
    ///
    public func discoverRESTAPIRootURL(for siteURL: String) async -> String? {
        await Self.coordinator.discover(siteURL: siteURL, session: session, cache: cache)
    }

    /// Resolves a working REST API root using discovery followed by conventional route probes.
    ///
    /// When HEAD discovery does not advertise a root, `/wp-json/` is tried first, followed by
    /// `?rest_route=/` for sites without pretty permalinks. A probed root is only accepted when
    /// the response is a valid WordPress REST API index.
    ///
    public func resolveRESTAPIRootURL(for siteURL: String) async -> String? {
        if let cachedRoot = cache.root(for: siteURL) {
            return cachedRoot
        }
        return await Self.coordinator.resolve(siteURL: siteURL, session: session, cache: cache)
    }
}

/// Actor that deduplicates in-flight REST API discovery and resolution requests.
///
/// When multiple callers request the same operation for a site URL concurrently,
/// only one set of requests is performed and all callers receive the same result.
///
private actor DiscoveryCoordinator {
    private struct RequestKey: Hashable {
        let siteURL: String
        let sessionID: ObjectIdentifier
        let cacheID: ObjectIdentifier

        init(siteURL: String, session: URLSessionProtocol, cache: WordPressRESTAPIRootCache) {
            self.siteURL = siteURL.trimSlashes().lowercased()
            self.sessionID = ObjectIdentifier(session)
            self.cacheID = ObjectIdentifier(cache)
        }
    }

    private var inFlightDiscoveries: [RequestKey: Task<String?, Never>] = [:]
    private var inFlightResolutions: [RequestKey: Task<String?, Never>] = [:]

    func discover(siteURL: String, session: URLSessionProtocol, cache: WordPressRESTAPIRootCache) async -> String? {
        let key = RequestKey(siteURL: siteURL, session: session, cache: cache)

        // Return existing in-flight task if one exists
        if let existing = inFlightDiscoveries[key] {
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

        inFlightDiscoveries[key] = task
        let result = await task.value
        inFlightDiscoveries[key] = nil
        return result
    }

    func resolve(siteURL: String, session: URLSessionProtocol, cache: WordPressRESTAPIRootCache) async -> String? {
        let key = RequestKey(siteURL: siteURL, session: session, cache: cache)
        if let existing = inFlightResolutions[key] {
            return await existing.value
        }

        let task = Task<String?, Never> {
            if let discoveredRoot = await self.discover(siteURL: siteURL, session: session, cache: cache) {
                return discoveredRoot
            }

            let candidates = [
                WordPressAPIDiscovery.defaultRESTAPIRootURL(for: siteURL),
                WordPressAPIDiscovery.queryRESTAPIRootURL(for: siteURL)
            ]
            for candidate in candidates where await Self.isRESTAPIIndex(root: candidate, session: session) {
                cache.setRoot(candidate, for: siteURL)
                return candidate
            }
            return nil
        }

        inFlightResolutions[key] = task
        let result = await task.value
        inFlightResolutions[key] = nil
        return result
    }

    private static func isRESTAPIIndex(root: String, session: URLSessionProtocol) async -> Bool {
        guard var components = URLComponents(string: root) else { return false }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "_fields", value: "namespaces"))
        components.queryItems = queryItems
        guard let url = components.url else { return false }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let index = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  index["namespaces"] is [Any] else {
                return false
            }
            return true
        } catch {
            DDLogDebug("⚠️ REST API root probe failed for \(root): \(error)")
            return false
        }
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
