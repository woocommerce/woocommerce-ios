import Foundation

/// Discovers the WordPress REST API root URL for a given site by performing a HEAD request
/// and parsing the `Link` response header per the WordPress REST API discovery specification.
///
/// See: https://developer.wordpress.org/rest-api/using-the-rest-api/discovery/
///
public struct WordPressAPIDiscovery {
    private let session: URLSessionProtocol

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    /// Discovers the REST API root URL by sending a HEAD request to the given site URL.
    ///
    /// - Parameter siteURL: The site URL to discover the REST API root for.
    /// - Returns: The discovered REST API root URL string, or `nil` if discovery fails.
    ///
    public func discoverRESTAPIRootURL(for siteURL: String) async -> String? {
        guard let url = URL(string: siteURL) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return nil }
            return parseRESTAPIRootURL(from: httpResponse)
        } catch {
            return nil
        }
    }
}

private extension WordPressAPIDiscovery {
    /// Parses the REST API root URL from the `Link` header of an HTTP response.
    ///
    /// The expected header format is:
    /// ```
    /// Link: <https://example.com/wp-json/>; rel="https://api.w.org/"
    /// ```
    ///
    func parseRESTAPIRootURL(from response: HTTPURLResponse) -> String? {
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
