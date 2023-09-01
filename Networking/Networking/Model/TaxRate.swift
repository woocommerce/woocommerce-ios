import Foundation
import Codegen

/// Represent a Tax Rate Entity.
///
public struct TaxRate: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    /// Tax rate id.
    ///
    public let id: Int64

    /// Tax rate name.
    ///
    public let name: String

    /// Tax rate country.
    ///
    public let country: String

    /// Tax rate countries.
    ///
    public let countries: [String]

    /// Tax rate postcode.
    ///
    public let postcode: String

    /// Tax rate postcodes.
    ///
    public let postcodes: [String]

    /// Tax rate priority.
    ///
    public let priority: Int64

    /// Tax rate.
    ///
    public let rate: String

    /// Tax rate order.
    ///
    public let order: Int64

    /// Tax rate class.
    ///
    public let taxRateClass: String

    /// Tax rate class.
    ///
    public let shipping: Bool

    /// Tax rate class.
    ///
    public let compound: Bool

    /// Tax rate city.
    ///
    public let city: String

    /// Tax rate cities.
    ///
    public let cities: [String]

    /// Default initializer for TaxClass.
    ///
    public init(id: Int64, name: String, country: String, countries: [String], postcode: String, postcodes: [String], priority: Int64, rate: String, order: Int64, taxRateClass: String, shipping: Bool, compound: Bool, city: String, cities: [String]) {
        self.id = id
        self.name = name
        self.country = country
        self.countries = countries
        self.postcode = postcode
        self.postcodes = postcodes
        self.priority = priority
        self.rate = rate
        self.order = order
        self.taxRateClass = taxRateClass
        self.shipping = shipping
        self.compound = compound
        self.city = city
        self.cities = cities
    }


    /// The public initializer for TaxClass.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(Int64.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let country = try container.decode(String.self, forKey: .country)
        let countries = try container.decode([String].self, forKey: .countries)
        let postcode = try container.decode(String.self, forKey: .postcode)
        let postcodes = try container.decode([String].self, forKey: .postcodes)
        let priority = try container.decode(Int64.self, forKey: .priority)
        let rate = try container.decode(String.self, forKey: .rate)
        let order = try container.decode(Int64.self, forKey: .order)
        let taxRateClass = try container.decode(String.self, forKey: .taxRateClass)
        let shipping = try container.decode(Bool.self, forKey: .shipping)
        let compound = try container.decode(Bool.self, forKey: .compound)
        let city = try container.decode(String.self, forKey: .city)
        let cities = try container.decode([String].self, forKey: .cities)


        self.init(id: id, name: name, country: country, countries: countries, postcode: postcode, postcodes: postcodes, priority: priority, rate: rate, order: order, taxRateClass: taxRateClass, shipping: shipping, compound: compound, city: city, cities: cities)
    }
}

/// Defines all of the TaxRate CodingKeys
///
private extension TaxRate {
    enum CodingKeys: String, CodingKey {
        case id
        case country
        case countries
        case state
        case postcode
        case postcodes
        case city
        case cities
        case rate
        case name
        case priority
        case compound
        case shipping
        case order
        case taxRateClass = "class"
    }
}
