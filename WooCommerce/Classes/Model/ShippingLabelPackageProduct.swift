import Foundation

/// A struct that keeps information about products contained in a package in Shipping Label purchase flow.
///
struct ShippingLabelPackageProduct {
    /// ID of the product
    let productID: Int64

    /// Name of the product
    let name: String

    /// Weight of the product
    let weight: Double

    /// Quantity of the product
    let quantity: Decimal

    /// Attributes of the product
    let attributes: [VariationAttributeViewModel]
}
