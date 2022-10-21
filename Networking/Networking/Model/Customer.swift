import Foundation
import Codegen

/// Represents a Customer entity:
/// https://woocommerce.github.io/woocommerce-rest-api-docs/#customer-properties
///
public struct Customer: Codable, GeneratedCopiable, GeneratedFakeable {
    /// The siteID for the customer
    public let siteID: Int64

    /// Unique identifier for the customer
    public let customerID: Int64

    /// The email address for the customer
    public let email: String

    /// Customer first name
    public let firstName: String?

    /// Customer last name
    public let lastName: String?

    /// List of billing address data
    public let billing: Address?

    /// List of shipping address data
    public let shipping: Address?

    /// Customer struct initializer
    ///
    public init(siteID: Int64,
                customerID: Int64,
                email: String,
                firstName: String?,
                lastName: String?,
                billing: Address?,
                shipping: Address?) {
        self.siteID = siteID
        self.customerID = customerID
        self.email = email
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

        let customerID = try container.decode(Int64.self, forKey: .customerID)
        let email = try container.decode(String.self, forKey: .email)
        let firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        let billing = try? container.decode(Address.self, forKey: .billing)
        let shipping = try? container.decode(Address.self, forKey: .shipping)

        self.init(siteID: siteID,
                  customerID: customerID,
                  email: email,
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
        case customerID =       "id"
        case email
        case firstName =        "first_name"
        case lastName =         "last_name"
        case billing
        case shipping
    }

    enum CustomerDecodingError: Error {
        case missingSiteID
    }
}
