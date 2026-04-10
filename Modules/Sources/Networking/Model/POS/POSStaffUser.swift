import Foundation

/// A POS staff user returned by the staff status endpoint.
///
public struct POSStaffUser: Decodable, Equatable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let hasPIN: Bool

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case role
        case hasPIN = "has_pin"
    }

    public init(userID: Int64,
                displayName: String,
                role: String,
                hasPIN: Bool) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.hasPIN = hasPIN
    }
}

/// Response from GET /wc/v3/pos/auth/pin/status
///
public struct POSStaffStatusResponse: Decodable, Equatable {
    public let users: [POSStaffUser]

    public init(users: [POSStaffUser]) {
        self.users = users
    }
}
