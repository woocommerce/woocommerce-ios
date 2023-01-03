import Foundation
import Yosemite

/// Generates all possible variations from a product attributes
///
struct ProductVariationGenerator {

    /// Group a colection of attribute options.
    /// EG: [Size: Large, Color: Black, Fabric: Cotton]
    ///
    private struct Combination: Hashable {
        let options: [Option]
    }

    /// Represents an attribute option.
    /// EG: Size: Large
    ///
    private struct Option: Hashable {
        let attributeID: Int64
        let attributeName: String
        let value: String
    }

    /// Generates all possible variations from a product attributes.
    /// Additionally it excludes variations that already exists in the `variations` parameter.
    ///
    static func generateVariations(for product: Product, excluding variations: [ProductVariation]) -> [CreateProductVariation] {
        let allCombinations = getCombinations(from: product)
        let uniqueCombinations = filterExistingCombinations(allCombinations, existing: variations)
        return buildVariations(from: uniqueCombinations, for: product)
    }

    /// Generates all posible combination for a product attributes.
    ///
    private static func getCombinations(from product: Product) -> [Combination] {
        // Iterates through attributes while eceiving the previous combinations list.
        product.attributes.reduce([Combination(options: [])]) { combinations, attribute in
            combinations.flatMap { combination in
                // When receiving a previous combination list, we add each attribute to each previous combination util we finish with them.
                attribute.options.map { option in
                    Combination(options: combination.options + [Option(attributeID: attribute.attributeID, attributeName: attribute.name, value: option)])
                }
            }
        }
    }

    /// Removes the provided variations from the given combinations array.
    ///
    private static func filterExistingCombinations(_ combinations: [Combination], existing variations: [ProductVariation]) -> [Combination] {
        // Convert variations into combinations
        let existingCombinations = variations.map { existingVariation in
            let options = existingVariation.attributes.map { attibute in
                Option(attributeID: attibute.id, attributeName: attibute.name, value: attibute.option)
            }
            return Combination(options: options)
        }

        // Filter existing combinations.
        let existingSet = Set(existingCombinations)
        return combinations.filter { combination in
            !existingSet.contains(combination)
        }
    }

    /// Convert the provided combinations into `[CreateProductVariation]` types that are consumed by our Yosemite stores.
    ///
    private static func buildVariations(from combinations: [Combination], for product: Product) -> [CreateProductVariation] {
        combinations.map { combination in
            let attributes = combination.options.map { option in
                ProductVariationAttribute(id: option.attributeID, name: option.attributeName, option: option.value)
            }
            return CreateProductVariation(regularPrice: "", attributes: attributes)
        }
    }
}
