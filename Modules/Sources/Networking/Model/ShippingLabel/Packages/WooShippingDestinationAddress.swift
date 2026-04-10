import Foundation
import Codegen

public struct WooShippingDestinationAddress: Equatable, GeneratedFakeable, GeneratedCopiable {
    public let company: String
    public let address1: String
    public let address2: String
    public let city: String
    public let state: String
    public let postcode: String
    public let country: String
    public let phone: String
    public let name: String
    public let firstName: String
    public let lastName: String
    public let email: String

    public init(company: String,
                address1: String,
                address2: String,
                city: String,
                state: String,
                postcode: String,
                country: String,
                phone: String,
                name: String,
                firstName: String,
                lastName: String,
                email: String) {
        self.company = company
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.postcode = postcode
        self.country = country
        self.phone = phone
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}

// MARK: Decodable
extension WooShippingDestinationAddress: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let company = try container.decodeIfPresent(String.self, forKey: CodingKeys.company) ?? ""
        let address1 = try container.decodeIfPresent(String.self, forKey: CodingKeys.address1) ?? ""
        let address2 = try container.decodeIfPresent(String.self, forKey: CodingKeys.address2) ?? ""
        let city = try container.decodeIfPresent(String.self, forKey: CodingKeys.city) ?? ""
        let state = try container.decodeIfPresent(String.self, forKey: CodingKeys.state) ?? ""
        let postcode = try container.decodeIfPresent(String.self, forKey: CodingKeys.postcode) ?? ""
        let country = try container.decodeIfPresent(String.self, forKey: CodingKeys.country) ?? ""
        let phone = try container.decodeIfPresent(String.self, forKey: CodingKeys.phone) ?? ""
        let name = try container.decodeIfPresent(String.self, forKey: CodingKeys.name) ?? ""
        let firstName = try container.decodeIfPresent(String.self, forKey: CodingKeys.firstName) ?? ""
        let lastName = try container.decodeIfPresent(String.self, forKey: CodingKeys.lastName) ?? ""
        let email = try container.decodeIfPresent(String.self, forKey: CodingKeys.email) ?? ""

        self.init(company: company,
                  address1: address1,
                  address2: address2,
                  city: city,
                  state: state,
                  postcode: postcode,
                  country: country,
                  phone: phone,
                  name: name,
                  firstName: firstName,
                  lastName: lastName,
                  email: email)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.company, forKey: .company)
        try container.encode(self.address1, forKey: .address1)
        try container.encode(self.address2, forKey: .address2)
        try container.encode(self.city, forKey: .city)
        try container.encode(self.state, forKey: .state)
        try container.encode(self.postcode, forKey: .postcode)
        try container.encode(self.country, forKey: .country)
        try container.encode(self.phone, forKey: .phone)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.firstName, forKey: .firstName)
        try container.encode(self.lastName, forKey: .lastName)
        try container.encode(self.email, forKey: .email)
    }

    private enum CodingKeys: String, CodingKey {
        case company
        case address1 = "address_1"
        case address2 = "address_2"
        case city
        case state
        case postcode
        case country
        case phone
        case name = "name"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}
