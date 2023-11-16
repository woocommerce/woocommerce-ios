import Foundation
import Codegen

/// Represents the entity sent for creating a new Product Variation entity.
///
public struct CreateProductVariation: Encodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let regularPrice: String
    public let salePrice: String
    public let attributes: [ProductVariationAttribute]
    public let description: String
    public let image: ProductImage?
    public let subscription: ProductSubscription?

    public init(regularPrice: String,
                salePrice: String,
                attributes: [ProductVariationAttribute],
                description: String,
                image: ProductImage?,
                subscription: ProductSubscription?) {
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.attributes = attributes
        self.description = description
        self.image = image
        self.subscription = subscription
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(regularPrice, forKey: .regularPrice)
        try container.encode(salePrice, forKey: .salePrice)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(description, forKey: .description)
        try container.encode(image, forKey: .image)

        // Metadata
        let metaDataValuePairs = buildMetaDataValuePairs()
        if metaDataValuePairs.isEmpty == false {
            try container.encode(metaDataValuePairs, forKey: .metadata)
        }
    }

    private func buildMetaDataValuePairs() -> [KeyValuePair] {
        if let subscription {
            return subscription.toKeyValuePairs()
        }
        return []
    }
}

/// Defines all of the CreateProductVariation CodingKeys
///
private extension CreateProductVariation {

    enum CodingKeys: String, CodingKey {
        case regularPrice  = "regular_price"
        case salePrice     = "sale_price"
        case attributes
        case description
        case image
        case metadata      = "meta_data"
    }
}
