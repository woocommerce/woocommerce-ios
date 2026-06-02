import Foundation

/// One row of the `GET /wc/pos/v1/staff` response. Carries the WordPress user record
/// the iOS client caches and validates PIN entry against locally.
///
public struct POSStaffMember: Codable, Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String

    /// Server returns the full `$user->allcaps` map. Clients filter to POS-specific cap names.
    public let capabilities: [String: Bool]

    /// `nil` when the user has not set a PIN.
    public let pin: PINDetails?

    public init(userID: Int64, displayName: String,
                role: String, capabilities: [String: Bool], pin: PINDetails?) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
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
        case role
        case capabilities
        case pin
    }
}
