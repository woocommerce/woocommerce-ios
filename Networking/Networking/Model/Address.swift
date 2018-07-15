import Foundation


/// Represents an Address Entity.
///
public struct Address: Decodable {
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
    public init(firstName: String, lastName: String, company: String?, address1: String, address2: String?, city: String, state: String, postcode: String, country: String, phone: String?, email: String?) {
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

