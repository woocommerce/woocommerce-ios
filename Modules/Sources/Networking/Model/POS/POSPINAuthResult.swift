import Foundation

/// Response from POST /wc/v3/pos/auth/pin
/// Networking-layer model for PIN authentication results.
public struct POSPINAuthResult: Decodable {
    public let userID: Int64
    public let userLogin: String
    public let displayName: String
    public let role: String
    public let capabilities: [String: Bool]
    public let applicationPassword: String
    public let applicationPasswordUUID: String
    public let sessionExpires: String
    public let idleTimeoutSeconds: Int

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userLogin = "user_login"
        case displayName = "display_name"
        case role
        case capabilities
        case applicationPassword = "application_password"
        case applicationPasswordUUID = "application_password_uuid"
        case sessionExpires = "session_expires"
        case idleTimeoutSeconds = "idle_timeout_seconds"
    }

    public init(userID: Int64,
                userLogin: String,
                displayName: String,
                role: String,
                capabilities: [String: Bool],
                applicationPassword: String,
                applicationPasswordUUID: String,
                sessionExpires: String,
                idleTimeoutSeconds: Int) {
        self.userID = userID
        self.userLogin = userLogin
        self.displayName = displayName
        self.role = role
        self.capabilities = capabilities
        self.applicationPassword = applicationPassword
        self.applicationPasswordUUID = applicationPasswordUUID
        self.sessionExpires = sessionExpires
        self.idleTimeoutSeconds = idleTimeoutSeconds
    }
}
