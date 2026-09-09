import Foundation

public extension String {
    /// Trims forward slash
    ///
    /// - Returns: String after removing prefix and suffix "/"
    ///
    func trimSlashes() -> String {
        removingPrefix("/").removingSuffix("/")
    }

    /// Replaces an HTTP scheme with HTTPS while preserving all other URL components.
    ///
    /// This does not validate that the destination supports TLS. It only normalizes the
    /// scheme so callers do not attempt an insecure connection that iOS will reject.
    func normalizedToHTTPS() -> String {
        guard let originalURL = URL(string: self),
              originalURL.scheme?.lowercased() == "http" else {
            return self
        }

        var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.string ?? self
    }

    /// Whether normalizing this value to HTTPS changes it.
    var requiresHTTPSNormalization: Bool {
        normalizedToHTTPS() != self
    }
}
