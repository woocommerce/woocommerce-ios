import Foundation

public extension SystemStatus {
    /// Subtype for details about post types and count in system status.
    ///
    struct PostTypeCount: Decodable {
        public let type, count: String
    }
}
