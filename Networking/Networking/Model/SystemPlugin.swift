import Foundation
import Codegen

public struct SystemPlugin: Decodable, GeneratedFakeable, GeneratedCopiable {
    public let siteID: Int64
    public let plugin: String           // e.g. woocommerce/woocommerce.php
    public let name: String             // e.g. WooCommerce
    public let version: String          // e.g. 3.0.0-rc.1
    public let versionLatest: String    // e.g. 2.6.14
    public let url: String              // e.g. https://woocommerce.com/
    public let authorName: String       // e.g. Automattic
    public let authorUrl: String        // e.g. https://woocommerce.com
    public let networkActivated: Bool   // i.g false | true

    /// Struct initializer.
    ///
    public init(siteID: Int64,
                plugin: String,
                name: String,
                version: String,
                versionLatest: String,
                url: String,
                authorName: String,
                authorUrl: String,
                networkActivated: Bool) {
        self.siteID = siteID
        self.plugin = plugin
        self.name = name
        self.version = version
        self.versionLatest = versionLatest
        self.url = url
        self.authorName = authorName
        self.authorUrl = authorUrl
        self.networkActivated = networkActivated
    }

    /// The public initializer for SystemPlugin.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw SitePluginError.missingSiteID
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let plugin = try container.decode(String.self, forKey: .plugin)
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        let version = try container.decodeIfPresent(String.self, forKey: .version) ?? ""
        let versionLatest = try container.decodeIfPresent(String.self, forKey: .versionLatest) ?? ""
        let url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        let authorName = try container.decodeIfPresent(String.self, forKey: .authorName) ?? ""
        let authorUrl = try container.decodeIfPresent(String.self, forKey: .authorUrl) ?? ""
        let networkActivated = try container.decodeIfPresent(Bool.self, forKey: .networkActivated) ?? false

        self.init(siteID: siteID,
                  plugin: plugin,
                  name: name,
                  version: version,
                  versionLatest: versionLatest,
                  url: url,
                  authorName: authorName,
                  authorUrl: authorUrl,
                  networkActivated: networkActivated)
    }

}

/// Defines all of the SystemPlugin CodingKeys.
///
private extension SystemPlugin {

    enum CodingKeys: String, CodingKey {
        case plugin              = "plugin"
        case name                = "name"
        case version             = "version"
        case versionLatest       = "version_latest"
        case url                 = "url"
        case authorName          = "author_name"
        case authorUrl           = "author_url"
        case networkActivated    = "network_activated"
    }

    enum DescriptionCodingKeys: String, CodingKey {
        case raw      = "raw"
        case rendered = "rendered"
    }
}

// MARK: - Decoding Errors
//
enum SystemPluginError: Error {
    case missingSiteID
}
