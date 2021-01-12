import Foundation

/// Represents the entity sent for creating a new Product Variation entity.
///
public struct CreateProductVariation: Codable, Equatable {
    public let regularPrice: String
    public let attributes: [ProductVariationAttribute]

    public init(regularPrice: String, attributes: [ProductVariationAttribute]) {
        self.regularPrice = regularPrice
        self.attributes = attributes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(regularPrice, forKey: .regularPrice)
        try container.encode(attributes, forKey: .attributes)
    }
}

/// Defines all of the CreateProductVariation CodingKeys
///
private extension CreateProductVariation {

    enum CodingKeys: String, CodingKey {
        case regularPrice  = "regular_price"
        case attributes
    }
}
