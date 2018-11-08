import Foundation


/// Represents a WordPress.com Site.
///
public struct Site: Decodable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int

    /// Site's Name.
    ///
    public let name: String

    /// Site's Description.
    ///
    public let description: String

    /// Site's URL.
    ///
    public let url: String

    /// Short name for site's plan.
    ///
    public let plan: String

    /// Indicates if Jetpack is installed.
    ///
    public let isJetpackInstalled: Bool

    ///  Indicates if there is a WooCommerce Store Active.
    ///
    public let isWooCommerceActive: Bool

    /// Indicates if this site hosts a WordPress Store.
    ///
    public let isWordPressStore: Bool


    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        let siteContainer = try decoder.container(keyedBy: SiteKeys.self)

        siteID = try siteContainer.decode(Int.self, forKey: .siteID)
        name = try siteContainer.decode(String.self, forKey: .name)
        description = try siteContainer.decode(String.self, forKey: .description)
        url = try siteContainer.decode(String.self, forKey: .url)
        isJetpackInstalled = try siteContainer.decode(Bool.self, forKey: .jetpack)

        let optionsContainer = try siteContainer.nestedContainer(keyedBy: OptionKeys.self, forKey: .options)
        isWordPressStore = try optionsContainer.decode(Bool.self, forKey: .isWordPressStore)
        isWooCommerceActive = try optionsContainer.decode(Bool.self, forKey: .isWooCommerceActive)

        let planContainer = try siteContainer.nestedContainer(keyedBy: PlanKeys.self, forKey: .plan)
        plan = try planContainer.decode(String.self, forKey: .shortName)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int, name: String, description: String, url: String, plan: String, isJetpackInstalled: Bool, isWooCommerceActive: Bool, isWordPressStore: Bool) {
        self.siteID = siteID
        self.name = name
        self.description = description
        self.url = url
        self.plan = plan
        self.isJetpackInstalled = isJetpackInstalled
        self.isWordPressStore = isWordPressStore
        self.isWooCommerceActive = isWooCommerceActive
    }
}


// MARK: - Comparable Conformance
//
extension Site: Comparable {
    public static func == (lhs: Site, rhs: Site) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.name == rhs.name &&
            lhs.description == rhs.description &&
            lhs.url == rhs.url &&
            lhs.plan == rhs.plan &&
            lhs.isJetpackInstalled == rhs.isJetpackInstalled &&
            lhs.isWooCommerceActive == rhs.isWooCommerceActive &&
            lhs.isWordPressStore == rhs.isWordPressStore
    }

    public static func < (lhs: Site, rhs: Site) -> Bool {
        return lhs.siteID < rhs.siteID ||
            (lhs.siteID == rhs.siteID && lhs.name < rhs.name) ||
            (lhs.siteID == rhs.siteID && lhs.name == rhs.name && lhs.description < rhs.description)
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
        case jetpack        = "jetpack"
        case options        = "options"
        case plan           = "plan"
    }

    enum OptionKeys: String, CodingKey {
        case isWordPressStore = "is_wpcom_store"
        case isWooCommerceActive = "woocommerce_is_active"
    }

    enum PlanKeys: String, CodingKey {
        case shortName      = "product_name_short"
    }
}
