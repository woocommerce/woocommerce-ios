import Foundation
import Yosemite

/// Contains the logic for calculating if an array of `ProductVariation` has the same, different or missing values for a specific property.
///
final class BulkUpdateOptionsModel {
    private(set) var productVariations: [ProductVariation]

    init(productVariations: [ProductVariation]) {
        self.productVariations = productVariations
    }

    /// Represents if a property in a collection of `ProductVariation`  has the same value or different values or is missing.
    ///
    enum BulkValue: Equatable {
        /// All variations have the same value
        case value(String)
        /// When variations have mixed values.
        case mixed
        /// None of the variation has a value
        case none
    }

    /// Calculates and returns if a property, specified by a `ProductVariation` keypath , has the same value or different values or is missing
    /// over all product variations of this view model.
    ///
    func bulkValueOf(_ keypath: KeyPath<ProductVariation, String?>) -> BulkValue {
        let allValues = productVariations.map(keypath)
        let allValuesWithoutNilOrEmpty = allValues.compactMap { $0 }.filter { !$0.isEmpty }
        // filter all unique values that are not nil or empty
        let uniqueResults = allValuesWithoutNilOrEmpty.uniqued()

        // Return `.none` when there are no values to evaluate.
        guard let sameValue = uniqueResults.first else {
            return .none
        }

        if uniqueResults.count == 1 && allValues.count == allValuesWithoutNilOrEmpty.count {
            // If we have only 1 value and we did not had any nil/empty
            return .value(sameValue)
        } else {
            // If at least ony value is different, even if it is missing (nil/empty)
            return .mixed
        }

    }
}
