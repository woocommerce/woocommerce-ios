import Foundation
import Codegen

public struct SystemPlugin: Decodable, GeneratedFakeable, GeneratedCopiable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int64

    /// Plugin reference, e.g. woocommerce/woocommerce.php
    ///
    public let plugin: String

    /// Plugin name, e.g. WooCommerce
    ///
    public let name: String

    /// Version, e.g. 3.0.0-rc.1
    ///
    public let version: String

    /// Version latest, e.g. 2.6.14
    ///
    public let versionLatest: String

    /// Plugin url, e.g. https://woocommerce.com/
    ///
    public let url: String

    /// Author Name, e.g. Automattic
    ///
    public let authorName: String

    /// Author url, e.g. https://woocommerce.com
    ///
    public let authorUrl: String

    /// Network activated, i.g false | true
    ///
    public let networkActivated: Bool

    /// Is the plugin active, i.e. false | true
    ///
    public let active: Bool

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
                networkActivated: Bool,
                active: Bool) {
        self.siteID = siteID
        self.plugin = plugin
        self.name = name
        self.version = version
        self.versionLatest = versionLatest
        self.url = url
        self.authorName = authorName
        self.authorUrl = authorUrl
        self.networkActivated = networkActivated
        self.active = active
    }
    /// The public initializer for SystemPlugin.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw SystemPluginError.missingSiteID
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let plugin = try container.decode(String.self, forKey: .plugin)
        let name = try container.decode(String.self, forKey: .name)
        let version = try container.decode(String.self, forKey: .version)
        let versionLatest = try container.decode(String.self, forKey: .versionLatest)
        let url = try container.decode(String.self, forKey: .url)
        let authorName = try container.decode(String.self, forKey: .authorName)
        let authorUrl = try container.decode(String.self, forKey: .authorUrl)
        let networkActivated = try container.decode(Bool.self, forKey: .networkActivated)

        /// Active and in-active plugins share identical structure, but are stored in separate parts of the remote response
        /// (and without an active attribute in the response). So... we use the same decoder for active and in-active plugins
        /// and in SystemStatusMapper we apply the correct value for active (which here is defaulted to true)
        ///
        let active = true

        self.init(siteID: siteID,
                  plugin: plugin,
                  name: name,
                  version: version,
                  versionLatest: versionLatest,
                  url: url,
                  authorName: authorName,
                  authorUrl: authorUrl,
                  networkActivated: networkActivated,
                  active: active)
    }
}

/// Defines all of the SystemPlugin CodingKeys.
///
private extension SystemPlugin {

    enum CodingKeys: String, CodingKey {
        case plugin
        case name
        case version
        case versionLatest       = "version_latest"
        case url
        case authorName          = "author_name"
        case authorUrl           = "author_url"
        case networkActivated    = "network_activated"
    }
}

// MARK: - Decoding Errors
//
enum SystemPluginError: Error {
    case missingSiteID
}
