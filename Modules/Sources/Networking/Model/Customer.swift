import Foundation
import Codegen

/// Represents a Customer entity:
/// https://woocommerce.github.io/woocommerce-rest-api-docs/#customer-properties
///
/// This model is used in TWO different contexts:
/// 1. When fetching from `/wc/v3/customers/{id}` endpoint:
///    - `userID` = WordPress user ID (mapped from API "id" field)
///    - `customerID` = 0 (not available from this endpoint)
/// 2. When converting from Storage.Customer via toReadOnly():
///    - `userID` = WordPress user ID (if registered)
///    - `customerID` = Analytics customer ID (from WCAnalyticsCustomer)
///
public struct Customer: Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    /// The siteID for the customer
    public let siteID: Int64

    /// WordPress user ID (mapped from API "id" field)
    /// This is the WordPress user account identifier, not the analytics customer ID
    public let userID: Int64

    /// Analytics customer ID (only set when converting from Storage.Customer taking value from WCAnalyticsCustomer)
    /// This field is not mapped to any API response
    public let customerID: Int64

    /// The email address for the customer
    public let email: String

    /// Customer username
    public let username: String?

    /// Customer first name
    public let firstName: String?

    /// Customer last name
    public let lastName: String?

    /// List of billing address data
    public let billing: Address?

    /// List of shipping address data
    public let shipping: Address?

    /// Computed property to check if the customer is a guest
    public var isGuest: Bool {
        userID == 0
    }

    /// Customer struct initializer
    ///
    public init(siteID: Int64,
                userID: Int64,
                customerID: Int64 = 0,
                email: String,
                username: String?,
                firstName: String?,
                lastName: String?,
                billing: Address?,
                shipping: Address?) {
        self.siteID = siteID
        self.userID = userID
        self.customerID = customerID
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.billing = billing
        self.shipping = shipping
    }

    /// Public initializer for the Customer
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw CustomerDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let userID = try container.decode(Int64.self, forKey: .userID)
        let email = try container.decode(String.self, forKey: .email)
        let username = try container.decode(String.self, forKey: .username)
        let firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        let billing = try? container.decode(Address.self, forKey: .billing)
        let shipping = try? container.decode(Address.self, forKey: .shipping)

        self.init(siteID: siteID,
                  userID: userID,
                  email: email,
                  username: username,
                  firstName: firstName,
                  lastName: lastName,
                  billing: billing,
                  shipping: shipping
        )
    }
}

/// Defines all of the Customer CodingKeys
///
extension Customer {
    enum CodingKeys: String, CodingKey {
        case userID =           "id"
        case email
        case username
        case firstName =        "first_name"
        case lastName =         "last_name"
        case billing
        case shipping
    }

    enum CustomerDecodingError: Error {
        case missingSiteID
    }
}
