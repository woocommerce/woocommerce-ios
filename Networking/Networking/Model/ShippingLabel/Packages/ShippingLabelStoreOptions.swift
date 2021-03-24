import Foundation

/// Represents the store options returned in the packages details.
///
public struct ShippingLabelStoreOptions: Equatable, GeneratedFakeable {

    public let currencySymbol: String // eg. `$`
    public let dimensionUnit: String // eg. `in`
    public let weightUnit: String // eg. `oz`
    public let originCountry: String // eg. `US`


    public init(currencySymbol: String, dimensionUnit: String, weightUnit: String, originCountry: String) {
        self.currencySymbol = currencySymbol
        self.dimensionUnit = dimensionUnit
        self.weightUnit = weightUnit
        self.originCountry = originCountry
    }
}

// MARK: Decodable
extension ShippingLabelStoreOptions: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let currencySymbol = try container.decode(String.self, forKey: .currencySymbol)
        let dimensionUnit = try container.decode(String.self, forKey: .dimensionUnit)
        let weightUnit = try container.decode(String.self, forKey: .weightUnit)
        let originCountry = try container.decode(String.self, forKey: .originCountry)

        self.init(currencySymbol: currencySymbol, dimensionUnit: dimensionUnit, weightUnit: weightUnit, originCountry: originCountry)
    }

    private enum CodingKeys: String, CodingKey {
        case currencySymbol = "currency_symbol"
        case dimensionUnit = "dimension_unit"
        case weightUnit = "weight_unit"
        case originCountry = "origin_country"
    }
}
