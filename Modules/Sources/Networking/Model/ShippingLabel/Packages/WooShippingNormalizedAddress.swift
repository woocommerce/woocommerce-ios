import Foundation
import Codegen

/// Represents a normalized address for the WooCommerce Shipping extension.
///
public struct WooShippingNormalizedAddress: Equatable, GeneratedFakeable, GeneratedCopiable {
    /// The name of the company at the address.
    public let company: String

    /// The first name of the sender/receiver at the address.
    public let firstName: String

    /// The last name of the sender/receiver at the address.
    public let lastName: String

    /// Email of the sender/receiver
    public let email: String?

    /// The contact phone number at the address.
    public let phone: String

    /// The country the address is in (ISO code).
    public let country: String

    /// The state the address is in (ISO code).
    public let state: String

    /// The first line of address (street, number, floor, etc.).
    public let address1: String

    /// The second line of address, empty if the address is only one line.
    public let address2: String

    /// The city the address is in.
    public let city: String

    /// Postal code of the address.
    public let postcode: String

    public init(company: String,
                firstName: String,
                lastName: String,
                email: String?,
                phone: String,
                country: String,
                state: String,
                address1: String,
                address2: String,
                city: String,
                postcode: String) {
        self.company = company
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.country = country
        self.state = state
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.postcode = postcode
    }
}

// MARK: Codable
extension WooShippingNormalizedAddress: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        let company = try container.decode(String.self, forKey: .company)
        let email = try container.decodeIfPresent(String.self, forKey: .email)
        let phone = try container.decode(String.self, forKey: .phone)
        let country = try container.decode(String.self, forKey: .country)
        let state = try container.decode(String.self, forKey: .state)
        let address1 = try container.decodeIfPresent(String.self, forKey: .address1) ?? container.decode(String.self, forKey: .alternateAddress1)
        let address2 = try container.decode(String.self, forKey: .address2)
        let city = try container.decode(String.self, forKey: .city)
        let postcode = try container.decode(String.self, forKey: .postcode)

        self.init(company: company,
                  firstName: firstName,
                  lastName: lastName,
                  email: email,
                  phone: phone,
                  country: country,
                  state: state,
                  address1: address1,
                  address2: address2,
                  city: city,
                  postcode: postcode)
    }

    private enum CodingKeys: String, CodingKey {
        case company
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case country
        case state
        case address1 = "address"
        case alternateAddress1 = "address_1"
        case address2 = "address_2"
        case city
        case postcode
    }
}
