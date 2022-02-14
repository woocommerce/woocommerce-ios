import Foundation
import Yosemite

/// Helper to format product variation details, such as variation name or attributes.
///
struct ProductVariationFormatter {

    /// Generates a name for the product variation, given a list of the parent product attributes, e.g. "Blue - Any Size"
    /// - Parameters:
    ///   - variation: The product variation whose name is being generated
    ///   - allAttributes: A list of attributes from the parent `Product`
    ///
    func generateName(for variation: ProductVariation, from allAttributes: [ProductAttribute]) -> String {
        let variationAttributes = generateAttributes(for: variation, from: allAttributes)
        return variationAttributes.map { $0.nameOrValue }.joined(separator: " - ")
    }

    /// Generates the variation attributes, given a list of the parent product attributes.
    /// - Parameters:
    ///   - variation: The product variation whose attributes are being generated
    ///   - allAttributes: A list of attributes from the parent `Product`
    ///
    func generateAttributes(for variation: ProductVariation, from allAttributes: [ProductAttribute]) -> [VariationAttributeViewModel] {
        return allAttributes
            .sorted(by: { (lhs, rhs) -> Bool in
                lhs.position < rhs.position
            })
            .map { attribute -> VariationAttributeViewModel in
                guard let variationAttribute = variation.attributes.first(where: { $0.id == attribute.attributeID && $0.name == attribute.name }) else {
                return VariationAttributeViewModel(name: attribute.name)
            }
            return VariationAttributeViewModel(productVariationAttribute: variationAttribute)
        }
    }
}
