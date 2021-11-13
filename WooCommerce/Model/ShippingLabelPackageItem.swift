import Foundation
import Yosemite

/// A struct that keeps information about items contained in a package in Shipping Label purchase flow.
///
struct ShippingLabelPackageItem: Equatable {
    /// Unique ID of the package item
    let id = UUID().uuidString

    /// ID of the product or variation
    let productOrVariationID: Int64

    /// Name of the product or variation
    let name: String

    /// Weight of the product or variation
    let weight: Double

    /// Quantity of the product or variation
    let quantity: Decimal

    /// Value of the product or variation
    let value: Double

    /// Dimensions of the product or variation
    let dimensions: ProductDimensions

    /// Attributes of the variation
    let attributes: [VariationAttributeViewModel]
}

// MARK: Custom initializers
//
extension ShippingLabelPackageItem {
    init(copy: ShippingLabelPackageItem, quantity: Decimal) {
        self.name = copy.name
        self.productOrVariationID = copy.productOrVariationID
        self.quantity = quantity
        self.weight = copy.weight
        self.dimensions = copy.dimensions
        self.attributes = copy.attributes
        self.value = copy.value
    }

    init?(orderItem: OrderItem, products: [Product], productVariations: [ProductVariation]) {
        self.name = orderItem.name
        self.quantity = orderItem.quantity
        self.value = orderItem.price.doubleValue
        self.attributes = orderItem.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) }

        let isVariation = orderItem.variationID > 0
        let product = products.first { $0.productID == orderItem.productID }
        let productVariation = productVariations.first { $0.productVariationID == orderItem.variationID }

        if isVariation, let productVariation = productVariation, !productVariation.virtual {
            self.productOrVariationID = productVariation.productVariationID
            self.weight = Double(productVariation.weight ?? "0") ?? 0
            self.dimensions = productVariation.dimensions
        } else if let product = product, !product.virtual {
            self.productOrVariationID = product.productID
            self.weight = Double(product.weight ?? "0") ?? 0
            self.dimensions = product.dimensions
        } else {
            return nil
        }
    }
}
