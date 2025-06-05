import Networking
import Codegen

/// Store sytem information entity.
///
public struct SystemInformation: GeneratedFakeable, GeneratedCopiable {
    /// Store UUID
    ///
    public let storeID: String?

    /// Store plugins (Active, inactive)
    ///
    public let systemPlugins: [SystemPlugin]
    
    /// Available in WooCommerce version 9.9.0 and later.
    public let enabledFeatures: [String]?

    public init(storeID: String? = nil, systemPlugins: [SystemPlugin], enabledFeatures: [String]? = nil) {
        self.storeID = storeID
        self.systemPlugins = systemPlugins
        self.enabledFeatures = enabledFeatures
    }
}
