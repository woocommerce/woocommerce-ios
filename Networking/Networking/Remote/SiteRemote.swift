import Foundation

/// Protocol for `SiteRemote` mainly used for mocking.
public protocol SiteRemoteProtocol {
    /// Creates a site given
    /// - Parameters:
    ///   - name: The name of the site.
    ///   - flow: The creation flow to follow.
    /// - Returns: The response with the site creation.
    func createSite(name: String, flow: SiteCreationFlow) async throws -> SiteCreationResponse

    /// Launches a site publicly through WPCOM.
    /// - Parameter siteID: Remote WPCOM ID of the site.
    func launchSite(siteID: Int64) async throws

    /// Enables a free trial plan for a site.
    ///
    func enableFreeTrial(siteID: Int64, profilerData: SiteProfilerData?) async throws
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

    public func createSite(name: String, flow: SiteCreationFlow) async throws -> SiteCreationResponse {
        let path = Path.siteCreation
        let subdomainName = flow.domain.split(separator: ".").first

        // Do not allow nil subdomains on the `.onboarding` flow
        switch flow {
        case .onboarding where subdomainName == nil:
            throw SiteCreationError.invalidDomain
        default:
            break
        }

        let parameters: [String: Any] = [
            "blog_name": subdomainName ?? "",
            "blog_title": name,
            "client_id": dotcomClientID,
            "client_secret": dotcomClientSecret,
            "find_available_url": flow.useRandomURL,
            "public": 0,
            "validate": false,
            "options": [
                "default_annotation_as_primary_fallback": true,
                "site_creation_flow": flow.flowID,
                "site_information": [
                    "title": ""
                ],
                "theme": flow.theme,
                "use_theme_annotation": false,
                "wpcom_public_coming_soon": 1
            ] as [String: Any]
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)

        return try await enqueue(request)
    }

    public func launchSite(siteID: Int64) async throws {
        let path = Path.siteLaunch(siteID: siteID)
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path)
        return try await enqueue(request)
    }

    public func enableFreeTrial(siteID: Int64, profilerData: SiteProfilerData?) async throws {
        let path = Path.enableFreeTrial(siteID: siteID)
        let parameters: [String: Any]? = profilerData.map { profilerData in
            [
                "wpcom_woocommerce_onboarding": [
                    "blogname": profilerData.name,
                    "woocommerce_default_country": profilerData.countryCode,
                    "woocommerce_onboarding_profile": [
                        "industry": [
                            [
                                "slug": profilerData.categoryGroup, // TODO: we need to clarify this list from Ghidorah
                                "detail": profilerData.category // Only populated when it's a subcategory
                            ].compactMapValues { $0 }
                        ],
                        "is_store_country_set": true,
                        "selling_venues": profilerData.sellingStatus?.rawValue,
                        "other_platform": profilerData.sellingPlatforms as Any?
                    ].compactMapValues { $0 }
                ]
            ]
        }
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        return try await enqueue(request)
    }
}

/// Possible Site Creation Flows
///
public enum SiteCreationFlow {
    case onboarding(domain: String)
    case wooexpress

    var domain: String {
        switch self {
        case .onboarding(let domain):
            return domain
        case .wooexpress:
            return ""
        }
    }

    var useRandomURL: Bool {
        switch self {
        case .onboarding:
            return false
        case .wooexpress:
            return true
        }
    }

    var flowID: String {
        switch self {
        case .onboarding:
            return "onboarding"
        case .wooexpress:
            return "wooexpress"
        }
    }

    var theme: String {
        switch self {
        case .onboarding:
            return "pub/zoologist"
        case .wooexpress:
            return "pub/twentytwentytwo"
        }
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

/// Data from the site creation profiler questions.
public struct SiteProfilerData {
    public let name: String
    public let category: String?
    public let categoryGroup: String?
    public let sellingStatus: SellingStatus?
    public let sellingPlatforms: String?
    public let countryCode: String

    /// Selling status options.
    /// Its raw value is the value to be sent to the backend.
    /// https://github.com/Automattic/woocommerce.com/blob/trunk/themes/woo/start/config/options.json
    public enum SellingStatus: String {
        /// Just starting my business.
        case justStarting = "no"
        /// Already selling, but not online.
        case alreadySellingButNotOnline = "brick-mortar"
        /// Already selling online.
        case alreadySellingOnline = "other"
    }

    public init(name: String,
                category: String?,
                categoryGroup: String?,
                sellingStatus: SiteProfilerData.SellingStatus?,
                sellingPlatforms: String?,
                countryCode: String) {
        self.name = name
        self.category = category
        self.categoryGroup = categoryGroup
        self.sellingStatus = sellingStatus
        self.sellingPlatforms = sellingPlatforms
        self.countryCode = countryCode
    }
}

// MARK: - Constants
//
private extension SiteRemote {
    enum Path {
        static let siteCreation = "sites/new"
        static func siteLaunch(siteID: Int64) -> String {
            "sites/\(siteID)/launch"
        }

        ///Path to add enable the free trial on a site.
        ///
        static func enableFreeTrial(siteID: Int64) -> String {
            "sites/\(siteID)/ecommerce-trial/add/ecommerce-trial-bundle-monthly"
        }
    }
}
