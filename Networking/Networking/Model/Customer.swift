import Foundation
import Codegen

/// Represents a Customer entity:
/// https://woocommerce.github.io/woocommerce-rest-api-docs/#customer-properties
///
struct Customer: Codable {

    /// Unique identifier for the customer
    let customerID: Int64

    /// The email address for the customer
    let email: String

    /// Customer first name
    let firstName: String

    /// Customer last name
    let lastName: String
    // TODO: Check why both billing and shipping are making the decoder fail.
    /// List of billing address data
    //let billing: [String]

    /// List of shipping address data
    //let shipping: [String]

    /// Customer struct initializer
    ///
    public init(customerID: Int64,
                email: String,
                firstName: String,
                lastName: String) {
        self.customerID = customerID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }

    /// Public initializer for the Customer
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let customerID = try container.decode(Int64.self, forKey: .customerID)
        let email = try container.decode(String.self, forKey: .email)
        let firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""

        self.init(customerID: customerID,
            email: email,
            firstName: firstName,
            lastName: lastName
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
    }
}
