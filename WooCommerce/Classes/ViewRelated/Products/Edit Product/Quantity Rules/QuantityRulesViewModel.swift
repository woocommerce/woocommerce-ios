import Foundation

/// View Model for `QuantityRules`
///
final class QuantityRulesViewModel: ObservableObject {
    typealias Completion = (_ minQuantity: String, _ maxQuantity: String, _ groupOf: String) -> Void

    /// Minimum quantity
    ///
    @Published var minQuantity: String

    /// Maximum quantity
    ///
    @Published var maxQuantity: String

    /// Group of
    ///
    @Published var groupOf: String

    private let onCompletion: Completion

    init(minQuantity: String?,
         maxQuantity: String?,
         groupOf: String?,
         onCompletion: @escaping Completion) {
        self.minQuantity = QuantityRulesViewModel.getDisplayValue(for: minQuantity)
        self.maxQuantity = QuantityRulesViewModel.getDisplayValue(for: maxQuantity)
        self.groupOf = QuantityRulesViewModel.getDisplayValue(for: groupOf)
        self.onCompletion = onCompletion
    }

    convenience init(product: ProductFormDataModel,
                     onCompletion: @escaping Completion) {
        self.init(minQuantity: product.minAllowedQuantity,
                  maxQuantity: product.maxAllowedQuantity,
                  groupOf: product.groupOfQuantity,
                  onCompletion: onCompletion)
    }

    func onDoneButtonPressed() {
        onCompletion(minQuantity, maxQuantity, groupOf)
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
