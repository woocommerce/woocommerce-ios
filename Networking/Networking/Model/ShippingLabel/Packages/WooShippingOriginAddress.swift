import Foundation
import Codegen

public struct WooShippingOriginAddress: Equatable, GeneratedFakeable, GeneratedCopiable {
    public let id: String
    public let company: String?
    public let address1: String
    public let address2: String?
    public let city: String
    public let state: String?
    public let postcode: String
    public let country: String
    public let phone: String
    public let firstName: String
    public let lastName: String
    public let email: String
    public let defaultAddress: Bool
    public let isVerified: Bool
}

// MARK: Decodable
extension WooShippingOriginAddress: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: CodingKeys.id)
        let company = try container.decodeIfPresent(String.self, forKey: CodingKeys.company)
        let address1 = try container.decodeIfPresent(String.self, forKey: CodingKeys.address1) ?? ""
        let address2 = try container.decodeIfPresent(String.self, forKey: CodingKeys.address2)
        let city = try container.decode(String.self, forKey: CodingKeys.city)
        let state = try container.decodeIfPresent(String.self, forKey: CodingKeys.state)
        let postcode = try container.decode(String.self, forKey: CodingKeys.postcode)
        let country = try container.decode(String.self, forKey: CodingKeys.country)
        let phone = try container.decode(String.self, forKey: CodingKeys.phone)
        let firstName = try container.decodeIfPresent(String.self, forKey: CodingKeys.firstName) ?? ""
        let lastName = try container.decodeIfPresent(String.self, forKey: CodingKeys.lastName) ?? ""
        let email = try container.decodeIfPresent(String.self, forKey: CodingKeys.email) ?? ""

        let defaultAddress = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.defaultAddress) ?? false
        let isVerified = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.isVerified) ?? false

        self.init(id: id,
                  company: company,
                  address1: address1,
                  address2: address2,
                  city: city,
                  state: state,
                  postcode: postcode,
                  country: country,
                  phone: phone,
                  firstName: firstName,
                  lastName: lastName,
                  email: email,
                  defaultAddress: defaultAddress,
                  isVerified: isVerified)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case company
        case address1 = "address_1"
        case address2 = "address_2"
        case city
        case state
        case postcode
        case country
        case phone
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case defaultAddress = "default_address"
        case isVerified = "is_verified"
    }
}
