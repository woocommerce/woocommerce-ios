import Foundation

public extension SystemStatus {
    /// Subtype for details about post types and count in system status.
    ///
    struct PostTypeCount: Decodable {
    let type, count: String
}
}
