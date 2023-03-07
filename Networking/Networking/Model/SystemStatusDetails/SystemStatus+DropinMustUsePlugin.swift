import Foundation

public extension SystemStatus {
    /// Detail about drop-in / must-use plugin, which has minimal details compared to SystemPlugin
    ///
    struct DropinMustUsePlugin: Decodable {
        public let plugin: String
        public let name: String
    }
}
