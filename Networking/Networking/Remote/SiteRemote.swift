import Foundation

/// Protocol for `SiteRemote` mainly used for mocking.
public protocol SiteRemoteProtocol {
    /// Creates a site given
    /// - Parameters:
    ///   - name: The name of the site.
    ///   - domain: The domain selected for the site.
    /// - Returns: The response with the site creation.
    func createSite(name: String, domain: String) async throws -> SiteCreationResponse

    /// Launches a site publicly through WPCOM.
    /// - Parameter siteID: Remote WPCOM ID of the site.
    func launchSite(siteID: Int64) async throws
}

/// Site: Remote Endpoints
///
public class SiteRemote: Remote, SiteRemoteProtocol {
    private let dotcomClientID: String
    private let dotcomClientSecret: String

    public init(network: Network, dotcomClientID: String, dotcomClientSecret: String) {
        self.dotcomClientID = dotcomClientID
        self.dotcomClientSecret = dotcomClientSecret
        super.init(network: network)
    }

    public func createSite(name: String,
                           domain: String) async throws -> SiteCreationResponse {
        let path = Path.siteCreation

        // Domain input should be a `wordpress.com` subdomain.
        guard let subdomainName = domain.split(separator: ".").first else {
            throw SiteCreationError.invalidDomain
        }
        let parameters: [String: Any] = [
            "blog_name": subdomainName,
            "blog_title": name,
            "client_id": dotcomClientID,
            "client_secret": dotcomClientSecret,
            "find_available_url": false,
            "public": 0,
            "validate": false,
            "options": [
                "default_annotation_as_primary_fallback": true,
                "site_creation_flow": "onboarding",
                "site_information": [
                    "title": ""
                ],
                "theme": "pub/zoologist",
                "use_theme_annotation": false,
                "wpcom_public_coming_soon": 1
            ]
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)

        return try await enqueue(request)
    }

    public func launchSite(siteID: Int64) async throws {
        let path = "sites/\(siteID)/launch"
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path)
        return try await enqueue(request)
    }
}

/// Site creation API response.
public struct SiteCreationResponse: Decodable {
    public let site: Site
    public let success: Bool

    private enum CodingKeys: String, CodingKey {
        case site = "blog_details"
        case success
    }
}

/// Possible site creation errors in the Networking layer.
public enum SiteCreationError: Error {
    case invalidDomain
}

public extension SiteCreationResponse {
    /// Necessary data about the created site in the site creation API response.
    struct Site: Decodable, Equatable {
        public let siteID: String
        public let name: String
        public let url: String
        public let siteSlug: String

        private enum CodingKeys: String, CodingKey {
            case siteID = "blogid"
            case name = "blogname"
            case url
            case siteSlug = "site_slug"
        }
    }
}

// MARK: - Constants
//
private extension SiteRemote {
    enum Path {
        static let siteCreation = "sites/new"
    }
}
