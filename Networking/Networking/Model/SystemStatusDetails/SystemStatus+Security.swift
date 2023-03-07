import Foundation

public extension SystemStatus {
    /// Details about security of a store in its system status report.
    ///
    struct Security: Codable {
        public let secureConnection, hideErrors: Bool

        enum CodingKeys: String, CodingKey {
            case secureConnection = "secure_connection"
            case hideErrors = "hide_errors"
        }
    }
}
