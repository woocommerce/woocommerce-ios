import Foundation

/// Represents a specific plugin entity for a specific site.
///
public struct SitePlugin: Decodable, GeneratedFakeable {
    public let siteID: Int64
    public let plugin: String                   // e.g. woocommerce/woocommerce (i.e. [folder/]main php file)
    public let status: SitePluginStatusEnum     // i.e. .active | .networkActive | .inactive
    public let name: String                     // e.g. WooCommerce
    public let pluginUri: String                // e.g. https://woocommerce.com/
    public let author: String                   // e.g. Automattic
    public let authorUri: String                // e.g. https://woocommerce.com
    public let descriptionRaw: String           // e.g. An eCommerce toolkit that helps you sell anything...
    public let descriptionRendered: String      // e.g. An eCommerce toolkit... (likely to contain HTML tags)
    public let version: String                  // e.g. 5.1.0
    public let networkOnly: Bool                // i.e. false | true
    public let requiresWPVersion: String        // e.g. 5.4 (but often empty)
    public let requiresPHPVersion: String       // e.g. 7.0 (but often empty)
    public let textDomain: String               // e.g. woocommerce (occassionally empty)

    /// Struct initializer.
    ///
    public init(
        siteID: Int64,
        plugin: String,
        status: SitePluginStatusEnum,
        name: String,
        pluginUri: String,
        author: String,
        authorUri: String,
        descriptionRaw: String,
        descriptionRendered: String,
        version: String,
        networkOnly: Bool,
        requiresWPVersion: String,
        requiresPHPVersion: String,
        textDomain: String
    ) {
        self.siteID = siteID
        self.plugin = plugin
        self.status = status
        self.name = name
        self.pluginUri = pluginUri
        self.author = author
        self.authorUri = authorUri
        self.descriptionRaw = descriptionRaw
        self.descriptionRendered = descriptionRendered
        self.version = version
        self.networkOnly = networkOnly
        self.requiresWPVersion = requiresWPVersion
        self.requiresPHPVersion = requiresPHPVersion
        self.textDomain = textDomain
    }

    /// The public initializer for SitePlugin.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw SitePluginError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let plugin = try container.decode(String.self, forKey: .plugin)
        let status = try container.decode(SitePluginStatusEnum.self, forKey: .status)
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        let pluginUri = try container.decodeIfPresent(String.self, forKey: .pluginUri) ?? ""
        let author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
        let authorUri = try container.decodeIfPresent(String.self, forKey: .authorUri) ?? ""
        let version = try container.decodeIfPresent(String.self, forKey: .version) ?? ""
        let networkOnly = try container.decodeIfPresent(Bool.self, forKey: .networkOnly) ?? false
        let requiresWPVersion = try container.decodeIfPresent(String.self, forKey: .requiresWPVersion) ?? ""
        let requiresPHPVersion = try container.decodeIfPresent(String.self, forKey: .requiresPHPVersion) ?? ""
        let textDomain = try container.decodeIfPresent(String.self, forKey: .textDomain) ?? ""

        let descriptionContainer = try container.nestedContainer(keyedBy: DescriptionCodingKeys.self, forKey: .description)
        let descriptionRaw = try descriptionContainer.decodeIfPresent(String.self, forKey: .raw) ?? ""
        let descriptionRendered = try descriptionContainer.decodeIfPresent(String.self, forKey: .rendered) ?? ""

        self.init(
            siteID: siteID,
            plugin: plugin,
            status: status,
            name: name,
            pluginUri: pluginUri,
            author: author,
            authorUri: authorUri,
            descriptionRaw: descriptionRaw,
            descriptionRendered: descriptionRendered,
            version: version,
            networkOnly: networkOnly,
            requiresWPVersion: requiresWPVersion,
            requiresPHPVersion: requiresPHPVersion,
            textDomain: textDomain
        )
    }
}

/// Defines all of the SitePlugin CodingKeys.
///
private extension SitePlugin {

    enum CodingKeys: String, CodingKey {
        case plugin              = "plugin"
        case status              = "status"
        case name                = "name"
        case pluginUri           = "plugin_uri"
        case author              = "author"
        case authorUri           = "author_uri"
        case description         = "description"
        case version             = "version"
        case networkOnly         = "network_only"
        case requiresWPVersion   = "requires_wp"
        case requiresPHPVersion  = "requires_php"
        case textDomain          = "textdomain"
    }

    enum DescriptionCodingKeys: String, CodingKey {
        case raw      = "raw"
        case rendered = "rendered"
    }
}

// MARK: - Decoding Errors
//
enum SitePluginError: Error {
    case missingSiteID
}
