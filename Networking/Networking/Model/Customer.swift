import Foundation

/// Represent a Customer Entity.
///
public struct Customer: Decodable {

    public let siteID: Int64
    public let userID: Int64

    public let dateCreated: Date    // gmt
    public let dateModified: Date?  // gmt

    public let email: String
    public let username: String?
    public let firstName: String?
    public let lastName: String?
    public let gravatarUrl: String?

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
                gravatarUrl: String?,
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
        self.gravatarUrl = gravatarUrl

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
        let gravatarUrl = try container.decodeIfPresent(String.self, forKey: .gravatarUrl)

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
                  gravatarUrl: gravatarUrl,
                  isPaying: isPaying,
                  billingAddress: billingAddress,
                  shippingAddress: shippingAddress)
    }
}

// MARK: - Equatable Conformance
//
extension Customer: Equatable {

    public static func == (lhs: Customer, rhs: Customer) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.userID == rhs.userID &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.dateModified == rhs.dateModified &&
            lhs.email == rhs.email &&
            lhs.username == rhs.username &&
            lhs.firstName == rhs.firstName &&
            lhs.lastName == rhs.lastName &&
            lhs.gravatarUrl == rhs.gravatarUrl &&
            lhs.isPaying == rhs.isPaying &&
            lhs.billingAddress == rhs.billingAddress &&
            lhs.shippingAddress == rhs.shippingAddress
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
        case gravatarUrl = "avatar_url"
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
