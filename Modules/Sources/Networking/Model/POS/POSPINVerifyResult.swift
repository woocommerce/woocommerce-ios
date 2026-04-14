import Foundation

/// Response from POST /wc/v3/pos/auth/pin/verify
/// Verifies a PIN and returns the user's identity and capabilities
/// without creating an Application Password session.
public struct POSPINVerifyResult: Decodable, Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let capabilities: [String: Bool]

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case role
        case capabilities
    }
}
