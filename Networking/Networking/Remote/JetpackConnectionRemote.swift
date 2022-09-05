import Foundation
import WordPressKit

/// Handle API requests to the Jetpack REST API.
///
public final class JetpackConnectionRemote: Remote {
    private let siteURL: String

    public init(siteURL: String, network: Network) {
        self.siteURL = siteURL
        super.init(network: network)
    }

    /// Fetches the URL for setting up Jetpack connection.
    ///
    public func fetchJetpackConnectionURL(completion: @escaping (Result<URL, Error>) -> Void) {
        let request = WordPressOrgRequest(baseURL: siteURL, method: .get, path: Path.jetpackConnectionURL)
        let mapper = JetpackConnectionURLMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Fetches the user connected to a site's Jetpack if exists.
    ///
    public func fetchJetpackConnectionUser(completion: @escaping (Result<JetpackUser, Error>) -> Void) {
        let request = WordPressOrgRequest(baseURL: siteURL, method: .get, path: Path.jetpackConnectionData)
        let mapper = JetpackUserMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}

public extension JetpackConnectionRemote {
    enum ConnectionError: Int, Error {
        case malformedURL
        case currentUserNotFound
    }
}

private extension JetpackConnectionRemote {
    enum Path {
        static let jetpackConnectionURL = "/jetpack/v4/connection/url"
        static let jetpackConnectionData = "/jetpack/v4/connection/data"
    }
}
