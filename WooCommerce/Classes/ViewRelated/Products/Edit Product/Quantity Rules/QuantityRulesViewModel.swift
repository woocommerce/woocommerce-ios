import Foundation

/// View Model for `QuantityRules`
///
final class QuantityRulesViewModel {
    /// Minimum quantity
    ///
    let minQuantity: String

    /// Maximum quantity
    ///
    let maxQuantity: String

    /// Group of
    ///
    let groupOf: String

    init(minQuantity: String?,
         maxQuantity: String?,
         groupOf: String?) {
        self.minQuantity = QuantityRulesViewModel.getDescription(for: minQuantity, withPlaceholder: Localization.noMinQuantity)
        self.maxQuantity = QuantityRulesViewModel.getDescription(for: maxQuantity, withPlaceholder: Localization.noMaxQuantity)
        self.groupOf = QuantityRulesViewModel.getDescription(for: groupOf, withPlaceholder: Localization.noGroupOfQuantity)
    }

    convenience init(product: ProductFormDataModel) {
        self.init(minQuantity: product.minAllowedQuantity,
                  maxQuantity: product.maxAllowedQuantity,
                  groupOf: product.groupOfQuantity)
    }
}

private extension QuantityRulesViewModel {

    /// Returns a description of the provided quantity, using the placeholder if the quantity is nil or empty.
    ///
    static func getDescription(for quantity: String?, withPlaceholder placeholder: String) -> String {
        guard let quantity, quantity.isNotEmpty else {
            return placeholder
        }
        return quantity
    }

    enum Localization {
        static let noMinQuantity = NSLocalizedString("No minimum", comment: "Description when no minimum quantity is set in quantity rules.")
        static let noMaxQuantity = NSLocalizedString("No maximum", comment: "Description when no maximum quantity is set in quantity rules.")
        static let noGroupOfQuantity = NSLocalizedString("Not grouped", comment: "Description when no 'group of' quantity is set in quantity rules.")
    }
}
