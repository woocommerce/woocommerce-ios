import Foundation
import WordPressKit

/// Handle API requests to the Jetpack REST API.
///
public struct JetpackConnectionRemote {
    private let api: WordPressOrgAPI

    init(api: WordPressOrgAPI) {
        self.api = api
    }

    /// Convenience init using site URL and authenticator
    ///
    public init?(siteURL: String, authenticator: Authenticator) {
        guard let baseURL = try? (siteURL + Path.basePath).asURL() else {
            return nil
        }
        self.init(api: WordPressOrgAPI(apiBase: baseURL, authenticator: authenticator))
    }

    /// Fetches the URL for setting up Jetpack connection.
    ///
    public func fetchJetpackConnectionURL() async throws -> URL? {
        let data = try await api.request(method: .get, path: Path.jetpackConnectionURL, parameters: nil)
        if let data = data, let escapedString = String(data: data, encoding: .utf8) {
            // The API returns an escaped string with double quotes, so we need to clean it up.
            let urlString = escapedString
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\\", with: "")
            return try urlString.asURL()
        }
        return nil
    }
}

private extension JetpackConnectionRemote {
    enum Path {
        static let basePath = "/wp-json/"
        static let jetpackConnectionURL = "/jetpack/v4/connection/url"
    }
}
