import Foundation
import Yosemite

/// Yosemite.ProductVariation helper methods
///
extension ProductVariation {

    /// Generates a name for the product variation, given a list of the parent product attributes, e.g. "Blue - Any Size"
    /// - Parameter allAttributes: A list of attributes from the parent `Product`
    ///
    func generateVariationName(from allAttributes: [ProductAttribute]) -> String {
        let variationAttributes = generateVariationAttributes(from: allAttributes)
        return variationAttributes.map { $0.nameOrValue }.joined(separator: " - ")
    }

    /// Generates the variation attributes, given a list of the parent product attributes.
    /// - Parameter allAttributes: A list of attributes from the parent `Product`
    ///
    func generateVariationAttributes(from allAttributes: [ProductAttribute]) -> [VariationAttributeViewModel] {
        return allAttributes
            .sorted(by: { (lhs, rhs) -> Bool in
                lhs.position < rhs.position
            })
            .map { productAttribute -> VariationAttributeViewModel in
            guard let variationAttribute = attributes.first(where: { $0.id == productAttribute.attributeID && $0.name == productAttribute.name }) else {
                return VariationAttributeViewModel(name: productAttribute.name)
            }
            return VariationAttributeViewModel(productVariationAttribute: variationAttribute)
        }
    }
}
