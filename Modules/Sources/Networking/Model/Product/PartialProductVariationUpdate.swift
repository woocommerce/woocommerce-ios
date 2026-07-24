import Foundation

/// Represents the entity sent for updating an existing Product Variation entity (e.g. bulk update).
/// Encodes only the fields that are set, so untouched fields (like `sku` / `global_unique_id`) are
/// never re-sent — avoiding server-side re-validation of fields the user did not change.
///
public struct PartialProductVariationUpdate: Encodable, Equatable {
    public let productVariationID: Int64
    public let regularPrice: String?

    public init(productVariationID: Int64, regularPrice: String? = nil) {
        self.productVariationID = productVariationID
        self.regularPrice = regularPrice
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productVariationID, forKey: .id)
        try container.encodeIfPresent(regularPrice, forKey: .regularPrice)
    }
}

private extension PartialProductVariationUpdate {
    enum CodingKeys: String, CodingKey {
        case id
        case regularPrice = "regular_price"
    }
}
