#if os(iOS)

import Foundation
import Codegen

/// Represents a specific plugin for a specific site from WPCOM endpoints.
///
public struct DotcomSitePlugin: Decodable, GeneratedFakeable, GeneratedCopiable {
    /// ID of the plugin.
    /// Examples: "jetpack/jetpack", "woocommerce/woocommerce"
    public let id: String

    /// Whether the plugin is activated.
    public let isActive: Bool

    public init(id: String, isActive: Bool) {
        self.id = id
        self.isActive = isActive
    }
}

/// Defines all of the DotcomSitePlugin CodingKeys.
///
private extension DotcomSitePlugin {
    enum CodingKeys: String, CodingKey {
        case id
        case isActive = "active"
    }
}

#endif
