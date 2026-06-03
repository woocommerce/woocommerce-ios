import Foundation

/// One row of the `GET /wc/pos/v1/staff` response. Carries the WordPress user record
/// the iOS client caches and validates PIN entry against locally.
///
public struct POSStaffMember: Codable, Equatable, Sendable {
    public let userID: Int64
    public let displayName: String

    /// Server-side preset name (formerly the WordPress role). Examples: `pos_cashier`,
    /// `pos_manager`, `administrator`. Carried as an opaque string — the client only uses
    /// it for display labelling, not for permission checks.
    public let preset: String

    /// POS-specific capabilities the staff member holds, keyed by the `pos_*` capability
    /// identifier with a boolean value. The server emits only granted entries (all values
    /// are `true` in the current preset bundles), so this is effectively a subset of
    /// `POSCapability.allCases`.
    public let capabilities: [String: Bool]

    /// `nil` when the user has not set a PIN.
    public let pin: PINDetails?

    public init(userID: Int64, displayName: String,
                preset: String, capabilities: [String: Bool], pin: PINDetails?) {
        self.userID = userID
        self.displayName = displayName
        self.preset = preset
        self.capabilities = capabilities
        self.pin = pin
    }

    public struct PINDetails: Codable, Equatable, Sendable {
        public let algo: String
        public let iterations: Int
        public let salt: String  // base64
        public let hash: String  // base64

        public init(algo: String, iterations: Int, salt: String, hash: String) {
            self.algo = algo
            self.iterations = iterations
            self.salt = salt
            self.hash = hash
        }
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case preset
        case capabilities
        case pin
    }
}
