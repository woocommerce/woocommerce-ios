/// Configuration of a bundled order item from the configuration UI. It contains necessary information to save the configuration remotely.
public struct BundledProductConfiguration: Equatable {
    public enum ProductOrVariation: Equatable {
        case product(id: Int64)
        case variation(productID: Int64, variationID: Int64, attributes: [ProductVariationAttribute])
    }

    let bundledItemID: Int64

    let productOrVariation: ProductOrVariation

    public let quantity: Decimal

    /// `nil` when it's not optional.
    let isOptionalAndSelected: Bool?

    public init(bundledItemID: Int64,
                productOrVariation: BundledProductConfiguration.ProductOrVariation,
                quantity: Decimal,
                isOptionalAndSelected: Bool? = nil) {
        self.bundledItemID = bundledItemID
        self.productOrVariation = productOrVariation
        self.quantity = quantity
        self.isOptionalAndSelected = isOptionalAndSelected
    }
}
