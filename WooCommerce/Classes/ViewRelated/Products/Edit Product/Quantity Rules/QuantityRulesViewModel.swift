import Foundation

/// View Model for `QuantityRules`
///
final class QuantityRulesViewModel: ObservableObject {
    /// Minimum quantity
    ///
    @Published var minQuantity: String

    /// Maximum quantity
    ///
    @Published var maxQuantity: String

    /// Group of
    ///
    @Published var groupOf: String

    init(minQuantity: String?,
         maxQuantity: String?,
         groupOf: String?) {
        self.minQuantity = QuantityRulesViewModel.getDisplayValue(for: minQuantity)
        self.maxQuantity = QuantityRulesViewModel.getDisplayValue(for: maxQuantity)
        self.groupOf = QuantityRulesViewModel.getDisplayValue(for: groupOf)
    }

    convenience init(product: ProductFormDataModel) {
        self.init(minQuantity: product.minAllowedQuantity,
                  maxQuantity: product.maxAllowedQuantity,
                  groupOf: product.groupOfQuantity)
    }
}

private extension QuantityRulesViewModel {

    /// Returns the display value of the provided quantity, using empty string if the quantity is not set.
    ///
    static func getDisplayValue(for quantity: String?) -> String {
        guard let quantity, quantity.isAValidProductQuantityRuleValue else {
            return ""
        }
        return quantity
    }
}
