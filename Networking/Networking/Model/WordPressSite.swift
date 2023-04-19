import Foundation

/// Represents basic information for a WordPress site.
///
public struct WordPressSite: Decodable, Equatable {

    /// Site's Name.
    ///
    public let name: String

    /// Site's Description.
    ///
    public let description: String

    /// Site's URL.
    ///
    public let url: String

    /// Time zone identifier of the site (TZ database name).
    ///
    public let timezone: String

    /// Return the website UTC time offset, showing the difference in hours and minutes from UTC, from the westernmost (−12:00) to the easternmost (+14:00).
    ///
    public let gmtOffset: String

    /// Namespaces supported by the site.
    ///
    public let namespaces: [String]

    /// URL for authorizing application password if enabled.
    ///
    public let applicationPasswordAuthorizationURL: String?

    /// Whether WooCommerce is one of the active plugins in the site.
    ///
    public var isWooCommerceActive: Bool {
        namespaces.contains { $0.hasPrefix(Constants.wooNameSpace) }
    }

    public init(name: String,
                description: String,
                url: String,
                timezone: String,
                gmtOffset: String,
                namespaces: [String],
                applicationPasswordAuthorizationURL: String?) {
        self.name = name
        self.description = description
        self.url = url
        self.timezone = timezone
        self.gmtOffset = gmtOffset
        self.namespaces = namespaces
        self.applicationPasswordAuthorizationURL = applicationPasswordAuthorizationURL
    }

    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decode(String.self, forKey: .description)
        let url = try container.decode(String.self, forKey: .url)
        let timezone = try container.decode(String.self, forKey: .timezone)
        let gmtOffset: String = try {
            do {
                return try container.decode(String.self, forKey: .gmtOffset)
            } catch {
                let double = try container.decode(Double.self, forKey: .gmtOffset)
                return double.description
            }
        }()
        let namespaces = try container.decode([String].self, forKey: .namespaces)
        let authentication = try? container.decode(Authentication.self, forKey: .authentication)
        let applicationPasswordURL = authentication?.applicationPasswords?.endpoints?.authorization

        self.init(name: name,
                  description: description,
                  url: url,
                  timezone: timezone,
                  gmtOffset: gmtOffset,
                  namespaces: namespaces,
                  applicationPasswordAuthorizationURL: applicationPasswordURL)
    }
}

public extension WordPressSite {
    /// Converts to `Site` with placeholder values for unknown fields.
    ///
    var asSite: Site {
        .init(siteID: WooConstants.placeholderSiteID, // Placeholder site ID
              name: name,
              description: description,
              url: url,
              adminURL: url + Constants.adminPath, // this would not work for sites with custom URLs
              loginURL: url + Constants.loginPath, // this would not work for sites with custom URLs
              frameNonce: "",
              plan: "",
              isJetpackThePluginInstalled: false,
              isJetpackConnected: false,
              isWooCommerceActive: isWooCommerceActive,
              isWordPressComStore: false,
              jetpackConnectionActivePlugins: [],
              timezone: timezone,
              gmtOffset: Double(gmtOffset) ?? 0,
              isPublic: false)
    }

    struct Authentication: Decodable {
        let applicationPasswords: ApplicationPasswords?
        enum CodingKeys: String, CodingKey {
            case applicationPasswords = "application-passwords"
        }
    }

    struct ApplicationPasswords: Decodable {
        let endpoints: Endpoints?
    }

    struct Endpoints: Decodable {
        let authorization: String?
    }
}

/// Defines all of the WordPressSite CodingKeys
///
private extension WordPressSite {
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case url
        case timezone = "timezone_string"
        case gmtOffset = "gmt_offset"
        case namespaces
        case authentication
    }

    enum Constants {
        static let adminPath = "/wp-admin/"
        static let loginPath = "/wp-login.php"
        static let wooNameSpace = "wc/"
    }
}
