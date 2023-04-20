import Foundation
import Codegen

/// Represents a WordPress.com Site.
///
public struct Site: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int64

    /// Site's Name.
    ///
    public let name: String

    /// Site's Description.
    ///
    public let description: String

    /// Site's URL.
    ///
    public let url: String

    /// Site's admin URL.
    ///
    public let adminURL: String

    /// Site's login URL.
    ///
    public let loginURL: String

    public let frameNonce: String

    /// Short name for site's plan.
    ///
    public let plan: String

    /// Whether the site has Jetpack-the-plugin installed.
    ///
    public let isJetpackThePluginInstalled: Bool

    /// Whether the site is connected to Jetpack, either through Jetpack-the-plugin or other plugins that include Jetpack Connection Package.
    ///
    public let isJetpackConnected: Bool

    ///  Indicates if there is a WooCommerce Store Active.
    ///
    public let isWooCommerceActive: Bool

    /// Indicates if this site is hosted on WordPress.com.
    ///
    public let isWordPressComStore: Bool

    /// For Jetpack CP sites (connected to Jetpack with Jetpack Connection Package instead of Jetpack-the-plugin), this property contains
    /// a list of active plugins with Jetpack Connection Package (e.g. WooCommerce Payments, Jetpack Backup).
    ///
    public let jetpackConnectionActivePlugins: [String]

    /// Time zone identifier of the site (TZ database name).
    ///
    public let timezone: String

    /// Return the website UTC time offset, showing the difference in hours and minutes from UTC, from the westernmost (−12:00) to the easternmost (+14:00).
    ///
    public let gmtOffset: Double

    /// Whether the site is launched and public.
    ///
    public let isPublic: Bool

    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        let siteContainer = try decoder.container(keyedBy: SiteKeys.self)

        let siteID = try siteContainer.decode(Int64.self, forKey: .siteID)
        let name = try siteContainer.decode(String.self, forKey: .name)
        let description = try siteContainer.decode(String.self, forKey: .description)
        let url = try siteContainer.decode(String.self, forKey: .url)
        let isJetpackThePluginInstalled = try siteContainer.decode(Bool.self, forKey: .isJetpackThePluginInstalled)
        let isJetpackConnected = try siteContainer.decode(Bool.self, forKey: .isJetpackConnected)

        let optionsContainer = try siteContainer.nestedContainer(keyedBy: OptionKeys.self, forKey: .options)
        let isWordPressComStore = try optionsContainer.decode(Bool.self, forKey: .isWordPressComStore)
        let isWooCommerceActive = try optionsContainer.decode(Bool.self, forKey: .isWooCommerceActive)
        let jetpackConnectionActivePlugins = try optionsContainer.decodeIfPresent([String].self, forKey: .jetpackConnectionActivePlugins) ?? []
        let timezone = try optionsContainer.decode(String.self, forKey: .timezone)
        let gmtOffset = try optionsContainer.decode(Double.self, forKey: .gmtOffset)
        let adminURL = try optionsContainer.decode(String.self, forKey: .adminURL)
        let loginURL = try optionsContainer.decode(String.self, forKey: .loginURL)
        let frameNonce = try optionsContainer.decode(String.self, forKey: .frameNonce)
        let isPublic = optionsContainer.failsafeDecodeIfPresent(booleanForKey: .isPublic) ?? false

        self.init(siteID: siteID,
                  name: name,
                  description: description,
                  url: url,
                  adminURL: adminURL,
                  loginURL: loginURL,
                  frameNonce: frameNonce,
                  plan: String(), // Not created on init. Added in supplementary API request.
                  isJetpackThePluginInstalled: isJetpackThePluginInstalled,
                  isJetpackConnected: isJetpackConnected,
                  isWooCommerceActive: isWooCommerceActive,
                  isWordPressComStore: isWordPressComStore,
                  jetpackConnectionActivePlugins: jetpackConnectionActivePlugins,
                  timezone: timezone,
                  gmtOffset: gmtOffset,
                  isPublic: isPublic)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int64,
                name: String,
                description: String,
                url: String,
                adminURL: String,
                loginURL: String,
                frameNonce: String,
                plan: String,
                isJetpackThePluginInstalled: Bool,
                isJetpackConnected: Bool,
                isWooCommerceActive: Bool,
                isWordPressComStore: Bool,
                jetpackConnectionActivePlugins: [String],
                timezone: String,
                gmtOffset: Double,
                isPublic: Bool) {
        self.siteID = siteID
        self.name = name
        self.description = description
        self.url = url
        self.adminURL = adminURL
        self.loginURL = loginURL
        self.frameNonce = frameNonce
        self.plan = plan
        self.isJetpackThePluginInstalled = isJetpackThePluginInstalled
        self.isJetpackConnected = isJetpackConnected
        self.isWordPressComStore = isWordPressComStore
        self.isWooCommerceActive = isWooCommerceActive
        self.jetpackConnectionActivePlugins = jetpackConnectionActivePlugins
        self.timezone = timezone
        self.gmtOffset = gmtOffset
        self.isPublic = isPublic
    }
}

public extension Site {
    /// Whether the site is connected to Jetpack with Jetpack Connection Package, and not with Jetpack-the-plugin.
    ///
    var isJetpackCPConnected: Bool {
        isJetpackConnected && !isJetpackThePluginInstalled
    }

    /// Whether the site has Jetpack plugin install, activated and connected.
    ///
    var isNonJetpackSite: Bool {
        /// when the site ID uses a placeholder ID, we can assume that it's not recognized by Jetpack,
        /// hence not a Jetpack site.
        siteID == WooConstants.placeholderSiteID
    }
}

/// Defines all of the Site CodingKeys.
///
private extension Site {

    enum SiteKeys: String, CodingKey {
        case siteID         = "ID"
        case name           = "name"
        case description    = "description"
        case url            = "URL"
        case options        = "options"
        case plan           = "plan"
        case isJetpackThePluginInstalled = "jetpack"
        case isJetpackConnected          = "jetpack_connection"
    }

    enum OptionKeys: String, CodingKey {
        case isWordPressComStore = "is_wpcom_store"
        case isWooCommerceActive = "woocommerce_is_active"
        case timezone = "timezone"
        case gmtOffset = "gmt_offset"
        case jetpackConnectionActivePlugins = "jetpack_connection_active_plugins"
        case adminURL = "admin_url"
        case loginURL = "login_url"
        case frameNonce = "frame_nonce"
        case isPublic = "blog_public"
    }

    enum PlanKeys: String, CodingKey {
        case shortName      = "product_name_short"
    }
}

/// Computed properties
///
public extension Site {

    /// Returns the TimeZone using the gmtOffset
    ///
    var siteTimezone: TimeZone {
        let secondsFromGMT = Int(gmtOffset * 3600)
        return TimeZone(secondsFromGMT: secondsFromGMT) ?? .current
    }

}
