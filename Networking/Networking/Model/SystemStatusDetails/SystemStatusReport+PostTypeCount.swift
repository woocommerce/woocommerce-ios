import Foundation

public extension SystemStatusReport {
    /// Subtype for details about post types and count in system status.
    ///
    struct PostTypeCount: Decodable {
        public let type, count: String
    }
}
