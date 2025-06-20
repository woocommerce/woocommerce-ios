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

    public init(storeID: String? = nil, systemPlugins: [SystemPlugin]) {
        self.storeID = storeID
        self.systemPlugins = systemPlugins
    }
}
