import Foundation

/// A struct that keeps information about items contained in a package in Shipping Label purchase flow.
///
struct ShippingLabelPackageItem: Equatable {
    /// ID of the product
    let productOrVariationID: Int64

    /// Name of the product
    let name: String

    /// Weight of the product
    let weight: Double

    /// Quantity of the product
    let quantity: Decimal

    /// Attributes of the product
    let attributes: [VariationAttributeViewModel]
}
