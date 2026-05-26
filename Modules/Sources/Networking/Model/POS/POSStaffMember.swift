import Foundation

/// A POS staff member returned by the `/wc-pos/v1/staff` endpoint.
///
/// The server holds the staff list authoritatively; mobile caches the response
/// and validates PIN entry locally against `pinHash` (PBKDF2-SHA256 of `pinSalt + pin`).
///
/// Members without a PIN configured (`hasPIN == false`) cannot sign in to POS
/// and are returned with `pinSalt`/`pinHash` empty.
public struct POSStaffMember: Codable, Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let hasPIN: Bool
    /// PBKDF2 salt, hex-encoded. Empty when `hasPIN == false`.
    public let pinSalt: String
    /// PBKDF2-SHA256 digest of `pinSalt + pin`, hex-encoded. Empty when `hasPIN == false`.
    public let pinHash: String
    /// PBKDF2 iteration count used to derive `pinHash`.
    public let pinIterations: Int

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case role
        case hasPIN = "has_pin"
        case pinSalt = "pin_salt"
        case pinHash = "pin_hash"
        case pinIterations = "pin_iterations"
    }

    public init(userID: Int64,
                displayName: String,
                role: String,
                hasPIN: Bool,
                pinSalt: String,
                pinHash: String,
                pinIterations: Int) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.hasPIN = hasPIN
        self.pinSalt = pinSalt
        self.pinHash = pinHash
        self.pinIterations = pinIterations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(Int64.self, forKey: .userID)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.role = try container.decode(String.self, forKey: .role)
        self.hasPIN = try container.decode(Bool.self, forKey: .hasPIN)
        self.pinSalt = try container.decodeIfPresent(String.self, forKey: .pinSalt) ?? ""
        self.pinHash = try container.decodeIfPresent(String.self, forKey: .pinHash) ?? ""
        self.pinIterations = try container.decodeIfPresent(Int.self, forKey: .pinIterations) ?? 0
    }
}

/// Envelope returned by `GET /wc-pos/v1/staff`.
public struct POSStaffListResponse: Codable, Equatable, Sendable {
    public let staff: [POSStaffMember]

    public init(staff: [POSStaffMember]) {
        self.staff = staff
    }
}
