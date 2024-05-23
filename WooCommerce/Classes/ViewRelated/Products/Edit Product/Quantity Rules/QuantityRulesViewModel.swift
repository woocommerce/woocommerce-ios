import Foundation

/// View Model for `QuantityRules`
///
final class QuantityRulesViewModel: ObservableObject {
     struct QuantityRules: Equatable {
        let minQuantity: String
        let maxQuantity: String
        let groupOf: String

        init(minQuantity: String,
             maxQuantity: String,
             groupOf: String) {
            // Let's normalize them for easier comparison
            self.minQuantity = minQuantity.isEmpty ? "0" : minQuantity
            self.maxQuantity = maxQuantity.isEmpty ? "0" : maxQuantity
            self.groupOf = groupOf.isEmpty ? "0" : groupOf
        }
    }

    typealias Completion = (_ rules: QuantityRules, _ hasUnchangedValues: Bool) -> Void

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

    private let originalInput: QuantityRules

    init(minQuantity: String?,
         maxQuantity: String?,
         groupOf: String?,
         onCompletion: @escaping Completion) {
        self.minQuantity = QuantityRulesViewModel.getDisplayValue(for: minQuantity)
        self.maxQuantity = QuantityRulesViewModel.getDisplayValue(for: maxQuantity)
        self.groupOf = QuantityRulesViewModel.getDisplayValue(for: groupOf)
        self.onCompletion = onCompletion
        self.originalInput = QuantityRules(minQuantity: minQuantity ?? "0", maxQuantity: maxQuantity ?? "0", groupOf: groupOf ?? "0")
    }

    convenience init(product: ProductFormDataModel,
                     onCompletion: @escaping Completion) {
        self.init(minQuantity: product.minAllowedQuantity,
                  maxQuantity: product.maxAllowedQuantity,
                  groupOf: product.groupOfQuantity,
                  onCompletion: onCompletion)
    }

    func onDoneButtonPressed() {
        let newRules = QuantityRules(minQuantity: minQuantity, maxQuantity: maxQuantity, groupOf: groupOf)
        onCompletion(newRules, newRules != originalInput)
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
