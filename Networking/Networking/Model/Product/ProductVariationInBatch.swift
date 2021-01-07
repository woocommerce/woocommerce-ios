import Foundation

/// Represents a Product Variation In Batch Entity, which contains the create/update/delete arrays.
///
public struct ProductVariationInBatch: Decodable, Equatable {
    public let create: [ProductVariation]
    public let update: [ProductVariation]
    public let delete: [ProductVariation]

    public init(create: [ProductVariation], update: [ProductVariation], delete: [ProductVariation]) {
        self.create = create
        self.update = update
        self.delete = delete
    }
}
