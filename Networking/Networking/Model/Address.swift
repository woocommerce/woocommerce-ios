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
    }
}
