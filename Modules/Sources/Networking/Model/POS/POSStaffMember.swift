import Foundation

/// One row of the `GET /wc/pos/v1/staff` response. Carries the WordPress user record
/// the iOS client caches and validates PIN entry against locally.
///
public struct POSStaffMember: Codable, Equatable, Sendable {
    public let userID: Int64
    public let displayName: String

    /// Server-side role preset, used only for display labelling — never for permission checks.
    /// Canonical presets are `pos_admin` / `pos_manager` / `pos_cashier`; see `POSStaffPreset`.
    public let preset: POSStaffPreset

    /// POS capabilities the staff member holds, keyed by the server's `pos_*` capability
    /// identifier. The server emits only granted entries (all values are `true` in the
    /// current preset bundles). Treated as opaque strings at this layer.
    public let capabilities: [String: Bool]

    /// `nil` when the user has not set a PIN.
    public let pin: PINDetails?

    public init(userID: Int64, displayName: String,
                preset: POSStaffPreset, capabilities: [String: Bool], pin: PINDetails?) {
        self.userID = userID
        self.displayName = displayName
        self.preset = preset
        self.capabilities = capabilities
        self.pin = pin
    }

    public struct PINDetails: Codable, Equatable, Sendable {
        public let algorithm: String
        public let iterations: Int
        public let salt: String
        public let hash: String

        public init(algorithm: String, iterations: Int, salt: String, hash: String) {
            self.algorithm = algorithm
            self.iterations = iterations
            self.salt = salt
            self.hash = hash
        }

        private enum CodingKeys: String, CodingKey {
            case algorithm = "algo"
            case iterations
            case salt
            case hash
        }
    }

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case preset
        case capabilities
        case pin
    }
}
