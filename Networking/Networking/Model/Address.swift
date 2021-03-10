import Foundation


/// Represents an Address Entity.
///
public struct Address: Decodable, GeneratedFakeable {
    public let firstName: String
    public let lastName: String
    public let company: String?
    public let address1: String
    public let address2: String?
    public let city: String
    public let state: String
    public let postcode: String
    public let country: String
    public let phone: String?
    public let email: String?

    /// Designated Initializer.
    ///
    public init(firstName: String,
                lastName: String,
                company: String?,
                address1: String,
                address2: String?,
                city: String,
                state: String,
                postcode: String,
                country: String,
                phone: String?,
                email: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.postcode = postcode
        self.country = country
        self.phone = phone
        self.email = email
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decode(String.self, forKey: .lastName)
        let company = try container.decodeIfPresent(String.self, forKey: .company)
        let address1 = try container.decode(String.self, forKey: .address1)
        let address2 = try container.decodeIfPresent(String.self, forKey: .address2)
        let city = try container.decode(String.self, forKey: .city)
        let state = try container.decode(String.self, forKey: .state)
        let postcode = try container.decode(String.self, forKey: .postcode)
        let country = try container.decode(String.self, forKey: .country)
        let phone = try container.decodeIfPresent(String.self, forKey: .phone)
        let email = try container.decodeIfPresent(String.self, forKey: .email)

        self.init(firstName: firstName,
                  lastName: lastName,
                  company: company,
                  address1: address1,
                  address2: address2,
                  city: city,
                  state: state,
                  postcode: postcode,
                  country: country,
                  phone: phone,
                  email: email)
    }
}


/// Defines all of the Address's CodingKeys.
///
private extension Address {

    enum CodingKeys: String, CodingKey {
        case firstName  = "first_name"
        case lastName   = "last_name"
        case company    = "company"
        case address1   = "address_1"
        case address2   = "address_2"
        case city       = "city"
        case state      = "state"
        case postcode   = "postcode"
        case country    = "country"
        case phone      = "phone"
        case email      = "email"
    }
}


// MARK: - Comparable Conformance
//
extension Address: Comparable {
    public static func == (lhs: Address, rhs: Address) -> Bool {
        return lhs.firstName == rhs.firstName &&
            lhs.lastName == rhs.lastName &&
            lhs.company == rhs.company &&
            lhs.address1 == rhs.address1 &&
            lhs.address2 == rhs.address2 &&
            lhs.city == rhs.city &&
            lhs.state == rhs.state &&
            lhs.postcode == rhs.postcode &&
            lhs.country == rhs.country &&
            lhs.phone == rhs.phone &&
            lhs.email == rhs.email
    }

    public static func < (lhs: Address, rhs: Address) -> Bool {
        return lhs.city < rhs.city ||
        (lhs.city == rhs.city && lhs.state < rhs.state) ||
        (lhs.city == rhs.city && lhs.state == rhs.state && lhs.postcode < rhs.postcode) ||
        (lhs.city == rhs.city && lhs.state == rhs.state && lhs.postcode == rhs.postcode && lhs.lastName < rhs.lastName)
    }
}
