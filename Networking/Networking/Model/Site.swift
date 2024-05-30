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

    /// Whether the site's user is the site's owner
    ///
    public let isSiteOwner: Bool

    public let frameNonce: String

    /// Short name for site's plan.
    ///
    public let plan: String

    /// Whether the site has AI assistant feature active.
    ///
    public let isAIAssistantFeatureActive: Bool

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
    public let visibility: SiteVisibility

    /// Whether the site is partially eligible for Blaze. For the site to be fully eligible for Blaze, `isAdmin` needs to be `true` as well.
    ///
    public let canBlaze: Bool

    /// Whether the site's user has the admin role.
    ///
    public let isAdmin: Bool

    /// Whether the site has even run an E-commerce trial plan.
    ///
    public let wasEcommerceTrial: Bool

    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        let siteContainer = try decoder.container(keyedBy: SiteKeys.self)

        let siteID = try siteContainer.decode(Int64.self, forKey: .siteID)
        let name = try siteContainer.decode(String.self, forKey: .name)
        let description = try siteContainer.decode(String.self, forKey: .description)
        let url = try siteContainer.decode(String.self, forKey: .url)
        let capabilitiesContainer = try siteContainer.nestedContainer(keyedBy: CapabilitiesKeys.self, forKey: .capabilities)
        let isSiteOwner = try capabilitiesContainer.decode(Bool.self, forKey: .isSiteOwner)
        let isAdmin = try capabilitiesContainer.decode(Bool.self, forKey: .isAdmin)
        let isJetpackThePluginInstalled = try siteContainer.decode(Bool.self, forKey: .isJetpackThePluginInstalled)
        let isJetpackConnected = try siteContainer.decode(Bool.self, forKey: .isJetpackConnected)
        let wasEcommerceTrial = try siteContainer.decode(Bool.self, forKey: .wasEcommerceTrial)
        let optionsContainer = try siteContainer.nestedContainer(keyedBy: OptionKeys.self, forKey: .options)
        let isWordPressComStore = try optionsContainer.decode(Bool.self, forKey: .isWordPressComStore)
        let isWooCommerceActive = try optionsContainer.decode(Bool.self, forKey: .isWooCommerceActive)
        let jetpackConnectionActivePlugins = try optionsContainer.decodeIfPresent([String].self, forKey: .jetpackConnectionActivePlugins) ?? []
        let timezone = try optionsContainer.decode(String.self, forKey: .timezone)
        let gmtOffset = try optionsContainer.decode(Double.self, forKey: .gmtOffset)
        let adminURL = try optionsContainer.decode(String.self, forKey: .adminURL)
        let loginURL = try optionsContainer.decode(String.self, forKey: .loginURL)
        let frameNonce = try optionsContainer.decode(String.self, forKey: .frameNonce)
        let canBlaze = optionsContainer.failsafeDecodeIfPresent(booleanForKey: .canBlaze) ?? false
        let visibility = optionsContainer.failsafeDecodeIfPresent(SiteVisibility.self, forKey: .visibility) ?? .privateSite

        let planContainer = try siteContainer.nestedContainer(keyedBy: PlanInfo.self, forKey: .plan)
        let plan = try planContainer.decode(String.self, forKey: .slug)

        let isAIAssistantFeatureActive: Bool = {
            guard let featuresContainer = try? planContainer.nestedContainer(keyedBy: Features.self, forKey: .features),
                  let activeFeatures = try? featuresContainer.decode([String].self, forKey: .active) else {
                return false
            }
            return activeFeatures.contains { $0 == Constants.aiAssistantFeature }
        }()

        self.init(siteID: siteID,
                  name: name,
                  description: description,
                  url: url,
                  adminURL: adminURL,
                  loginURL: loginURL,
                  isSiteOwner: isSiteOwner,
                  frameNonce: frameNonce,
                  plan: plan,
                  isAIAssistantFeatureActive: isAIAssistantFeatureActive,
                  isJetpackThePluginInstalled: isJetpackThePluginInstalled,
                  isJetpackConnected: isJetpackConnected,
                  isWooCommerceActive: isWooCommerceActive,
                  isWordPressComStore: isWordPressComStore,
                  jetpackConnectionActivePlugins: jetpackConnectionActivePlugins,
                  timezone: timezone,
                  gmtOffset: gmtOffset,
                  visibility: visibility,
                  canBlaze: canBlaze,
                  isAdmin: isAdmin,
                  wasEcommerceTrial: wasEcommerceTrial)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int64,
                name: String,
                description: String,
                url: String,
                adminURL: String,
                loginURL: String,
                isSiteOwner: Bool,
                frameNonce: String,
                plan: String,
                isAIAssistantFeatureActive: Bool,
                isJetpackThePluginInstalled: Bool,
                isJetpackConnected: Bool,
                isWooCommerceActive: Bool,
                isWordPressComStore: Bool,
                jetpackConnectionActivePlugins: [String],
                timezone: String,
                gmtOffset: Double,
                visibility: SiteVisibility,
                canBlaze: Bool,
                isAdmin: Bool,
                wasEcommerceTrial: Bool) {
        self.siteID = siteID
        self.name = name
        self.description = description
        self.url = url
        self.adminURL = adminURL
        self.loginURL = loginURL
        self.isSiteOwner = isSiteOwner
        self.frameNonce = frameNonce
        self.plan = plan
        self.isAIAssistantFeatureActive = isAIAssistantFeatureActive
        self.isJetpackThePluginInstalled = isJetpackThePluginInstalled
        self.isJetpackConnected = isJetpackConnected
        self.isWordPressComStore = isWordPressComStore
        self.isWooCommerceActive = isWooCommerceActive
        self.jetpackConnectionActivePlugins = jetpackConnectionActivePlugins
        self.timezone = timezone
        self.gmtOffset = gmtOffset
        self.visibility = visibility
        self.canBlaze = canBlaze
        self.isAdmin = isAdmin
        self.wasEcommerceTrial = wasEcommerceTrial
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

    /// Whether the site has been reverted to a simple site
    ///
    var isSimpleSite: Bool {
        plan == WooConstants.freePlanSlug
    }

    /// Whether the site is running a free trial WooExpress plan
    ///
    var isFreeTrialSite: Bool {
        plan == WooConstants.freeTrialPlanSlug
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
        case capabilities   = "capabilities"
        case options        = "options"
        case plan           = "plan"
        case isJetpackThePluginInstalled = "jetpack"
        case isJetpackConnected          = "jetpack_connection"
        case wasEcommerceTrial           = "was_ecommerce_trial"
    }

    enum PlanInfo: String, CodingKey {
        case slug = "product_slug"
        case features = "features"
    }

    enum Features: String, CodingKey {
        case active = "active"
    }

    enum CapabilitiesKeys: String, CodingKey {
        case isSiteOwner   = "own_site"
        case isAdmin = "manage_options"
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
        case visibility = "blog_public"
        case canBlaze = "can_blaze"
    }

    enum PlanKeys: String, CodingKey {
        case shortName      = "product_name_short"
    }
}

/// Enum representing the visibility status of a site.
///
public enum SiteVisibility: Int, Codable, GeneratedFakeable {
    case privateSite = -1
    case comingSoon = 0
    case publicSite = 1
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

    /// Returns true only if the site is hosted on WP.com and is private.
    ///
    var isPrivateWPCOMSite: Bool {
        return isWordPressComStore && (visibility == .privateSite)
    }
}

private extension Site {
    enum Constants {
        static let aiAssistantFeature = "ai-assistant"
    }
}
