import Foundation

/// Represents a Shipping Label Address.
///
public struct ShippingLabelAddress: Equatable {
    /// The name of the company at the address.
    public let company: String

    /// The name of the sender/receiver at the address.
    public let name: String

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
                name: String,
                phone: String,
                country: String,
                state: String,
                address1: String,
                address2: String,
                city: String,
                postcode: String) {
        self.company = company
        self.name = name
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
extension ShippingLabelAddress: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(company, forKey: .company)
        try container.encode(name, forKey: .name)
        try container.encode(phone, forKey: .phone)
        try container.encode(country, forKey: .country)
        try container.encode(state, forKey: .state)
        try container.encode(address1, forKey: .address1)
        try container.encode(address2, forKey: .address2)
        try container.encode(city, forKey: .city)
        try container.encode(postcode, forKey: .postcode)
    }

    private enum CodingKeys: String, CodingKey {
        case company
        case name
        case phone
        case country
        case state
        case address1 = "address"
        case address2 = "address_2"
        case city
        case postcode
    }
}

extension ShippingLabelAddress {
    /// This empty initializer is used when parsing the API response for shipping labels, because the origin/destination addresses are not available in each
    /// shipping label response and we have to manually populate them later.
    init() {
        self.init(company: "", name: "", phone: "", country: "", state: "", address1: "", address2: "", city: "", postcode: "")
    }
}
