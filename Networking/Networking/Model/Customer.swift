import Foundation

/// Represent a Customer Entity.
///
public struct Customer: Codable, Equatable {

    public let siteID: Int64
    public let userID: Int64

    public let dateCreated: Date    // gmt
    public let dateModified: Date?  // gmt

    public let email: String
    public let username: String?
    public let firstName: String?
    public let lastName: String?
    public let avatarUrl: String?

    public let role: Role
    public let isPaying: Bool

    public let billingAddress: Address?
    public let shippingAddress: Address?


    /// Struct initializer for Customer.
    ///
    public init(siteID: Int64,
                userID: Int64,
                dateCreated: Date,
                dateModified: Date?,
                email: String,
                username: String?,
                firstName: String?,
                lastName: String?,
                avatarUrl: String?,
                role: Role,
                isPaying: Bool,
                billingAddress: Address?,
                shippingAddress: Address?) {
        self.siteID = siteID
        self.userID = userID

        self.dateCreated = dateCreated
        self.dateModified = dateModified

        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl

        self.role = role
        self.isPaying = isPaying

        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
    }

    /// The public initializer for Customer.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw CustomerDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let userID = try container.decode(Int64.self, forKey: .userID)

        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified)

        let email = try container.decode(String.self, forKey: .email)
        let username = try container.decodeIfPresent(String.self, forKey: .username)
        let firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        let avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)

        let role = try container.decode(Role.self, forKey: .role)
        let isPaying = try container.decode(Bool.self, forKey: .isPaying)

        let billingAddress = try container.decodeIfPresent(Address.self, forKey: .billingAddress)
        let shippingAddress = try container.decodeIfPresent(Address.self, forKey: .shippingAddress)

        self.init(siteID: siteID,
                  userID: userID,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  email: email,
                  username: username,
                  firstName: firstName,
                  lastName: lastName,
                  avatarUrl: avatarUrl,
                  role: role,
                  isPaying: isPaying,
                  billingAddress: billingAddress,
                  shippingAddress: shippingAddress)
    }

    /// The public encoder for Customer.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(billingAddress, forKey: .billingAddress)
        try container.encode(shippingAddress, forKey: .shippingAddress)
    }
}

/// Defines all of the Customer CodingKeys
///
private extension Customer {

    enum CodingKeys: String, CodingKey {
        case userID = "id"

        case dateCreated = "date_created_gmt"
        case dateModified = "date_modified_gmt"

        case email
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"

        case role
        case isPaying = "is_paying_customer"

        case billingAddress = "billing"
        case shippingAddress = "shipping"
    }
}

// MARK: - Decoding Errors
//
enum CustomerDecodingError: Error {
    case missingSiteID
}
