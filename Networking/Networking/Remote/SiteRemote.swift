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
    func enableFreeTrial(siteID: Int64) async throws

    /// Uploads store profiler answers
    ///
    func uploadStoreProfilerAnswers(siteID: Int64, answers: StoreProfilerAnswers) async throws

    /// Loads a site.
    /// - Parameter siteID: Remote ID of the site to load.
    /// - Returns: The site that matches the site ID.
    func loadSite(siteID: Int64) async throws -> Site

    /// Update a site title.
    /// - Parameters:
    ///   - siteID: Remote ID of the site to update
    ///   - title: The new title to be set for the site
    ///
    func updateSiteTitle(siteID: Int64, title: String) async throws
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

    public func enableFreeTrial(siteID: Int64) async throws {
        let path = Path.enableFreeTrial(siteID: siteID)
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path)
        return try await enqueue(request)
    }

    public func uploadStoreProfilerAnswers(siteID: Int64, answers: StoreProfilerAnswers) async throws {
        let parameters: [String: Any] = {
            let industry: [String]? = {
                guard let category = answers.category else {
                    return nil
                }
                return [category]
            }()
            let onboarding: [String: Any?] = [
                "industry": industry,
                "is_store_country_set": answers.countryCode != nil,
                "business_choice": answers.sellingStatus?.remoteValue,
                "selling_platforms": answers.sellingPlatforms
            ]

            let params: [String: Any?] = [
                "woocommerce_onboarding_profile": onboarding.compactMapValues { $0 },
                "woocommerce_default_country": answers.countryCode
            ]
            return params.compactMapValues { $0 }
        }()

        let request = JetpackRequest(wooApiVersion: .wcAdmin,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.uploadStoreProfilerAnswers,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        return try await enqueue(request)
    }

    public func loadSite(siteID: Int64) async throws -> Site {
        let path = Path.loadSite(siteID: siteID)
        let parameters = [
            SiteParameter.Fields.key: SiteParameter.Fields.value,
            SiteParameter.Options.key: SiteParameter.Options.value
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        return try await enqueue(request)
    }

    public func updateSiteTitle(siteID: Int64, title: String) async throws {
        let parameters = [
            Fields.title: title
        ]
        let request = try DotcomRequest(wordpressApiVersion: .wpMark2,
                                        method: .post,
                                        path: Path.siteSettings(siteID: siteID),
                                        parameters: parameters,
                                        availableAsRESTRequest: true)
        try await enqueue(request)
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

/// Answers from the site creation profiler questions.
public struct StoreProfilerAnswers: Codable, Equatable {
    public let sellingStatus: SellingStatus?
    public let sellingPlatforms: String?
    public let category: String?
    public let countryCode: String?

    /// Selling status options.
    /// Its raw value is the value to be sent to the backend.
    /// https://github.com/woocommerce/woocommerce/blob/trunk/plugins/woocommerce-admin/client/core-profiler/pages/UserProfile.tsx#L20
    public enum SellingStatus: Codable {
        /// Just starting my business.
        case justStarting
        /// Already selling but not online
        case alreadySellingButNotOnline
        /// Already selling online
        case alreadySellingOnline

        public var remoteValue: String {
            switch self {
            case .justStarting:
                return "im_just_starting_my_business"
                // Sending same value because the core profiler endpoint doesn't have these options.
            case .alreadySellingButNotOnline, .alreadySellingOnline:
                return "im_already_selling"
            }
        }
    }

    public init(sellingStatus: StoreProfilerAnswers.SellingStatus?,
                sellingPlatforms: String?,
                category: String?,
                countryCode: String?) {
        self.sellingStatus = sellingStatus
        self.sellingPlatforms = sellingPlatforms
        self.category = category
        self.countryCode = countryCode
    }
}

/// Site Blaze status response.
private struct BlazeStatusResponse: Decodable {
    let isApproved: Bool

    private enum CodingKeys: String, CodingKey {
        case isApproved = "approved"
    }
}

extension SiteRemote {
    enum SiteParameter {
        enum Fields {
            static let key = "fields"
            static let value = "ID,name,description,URL,options,jetpack,jetpack_connection,capabilities,was_ecommerce_trial,plan"
        }
        enum Options {
            static let key = "options"
            static let value =
            "timezone,is_wpcom_store,woocommerce_is_active,gmt_offset,jetpack_connection_active_plugins,admin_url,login_url,frame_nonce,blog_public,can_blaze"
        }
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
        static let uploadStoreProfilerAnswers = "options"

        ///Path to add enable the free trial on a site.
        ///
        static func enableFreeTrial(siteID: Int64) -> String {
            "sites/\(siteID)/ecommerce-trial/add/ecommerce-trial-bundle-monthly"
        }

        static func loadSite(siteID: Int64) -> String {
            "sites/\(siteID)"
        }

        static func siteSettings(siteID: Int64) -> String {
            "sites/\(siteID)/settings"
        }
    }
    enum Fields {
        static let title = "title"
    }
}
