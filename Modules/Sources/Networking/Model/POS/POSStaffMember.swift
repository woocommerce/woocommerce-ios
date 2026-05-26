import Foundation

/// A POS staff member returned by the `/wc-pos/v1/staff` endpoint.
///
/// The server holds the staff list authoritatively; mobile caches the response
/// and validates PIN entry locally against `pin.hash` (PBKDF2-SHA256 of `pin.salt + pin`).
///
/// Members without a PIN configured have `pin == nil` and cannot sign in to POS;
/// they only exist in the list so admins can manage them via the wp-admin Staff page.
public struct POSStaffMember: Codable, Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    /// PIN derivation parameters when a PIN is configured. `nil` when this staff member
    /// has no PIN — they cannot authenticate at the lock screen.
    public let pin: PINDetails?

    public var hasPIN: Bool { pin != nil }

    /// PBKDF2 parameters used by the server to derive the stored hash.
    public struct PINDetails: Codable, Equatable, Sendable {
        /// Hashing algorithm identifier. M1 only supports `pbkdf2-sha256`.
        public let algo: String
        /// Iteration count used by the server when deriving `hash`.
        public let iterations: Int
        /// Base64-encoded salt. The mobile client base64-decodes this before feeding it
        /// into the local `CCKeyDerivationPBKDF` call.
        public let salt: String
        /// Base64-encoded PBKDF2-SHA256 digest of `salt + pin`. The mobile client
        /// base64-decodes this and constant-time-compares against the locally-derived digest.
        public let hash: String

        public init(algo: String, iterations: Int, salt: String, hash: String) {
            self.algo = algo
            self.iterations = iterations
            self.salt = salt
            self.hash = hash
        }
    }

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case role
        case pin
    }

    public init(userID: Int64,
                displayName: String,
                role: String,
                pin: PINDetails?) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.pin = pin
    }
}

/// Envelope returned by `GET /wc-pos/v1/staff`.
public struct POSStaffListResponse: Codable, Equatable, Sendable {
    public let staff: [POSStaffMember]

    public init(staff: [POSStaffMember]) {
        self.staff = staff
    }
}
