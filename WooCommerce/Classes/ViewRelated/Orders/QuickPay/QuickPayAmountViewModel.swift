import Foundation

/// View Model for the `QuickPayAmount` view.
///
final class QuickPayAmountViewModel: ObservableObject {

    /// Stores amount entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = formatAmount(amount)
        }
    }
}

// MARK: Helpers
private extension QuickPayAmountViewModel {

    /// Formats a received value by making sure the `$` symbol is present and trimming content to two decimal places.
    ///
    func formatAmount(_ amount: String) -> String {
        guard amount.isNotEmpty else { return amount }

        // Removes any unwanted character
        var formattedAmount = amount.filter { $0.isNumber || $0.isCurrencySymbol || $0 == "." }

        // Prepend the `$` symbol if needed.
        if formattedAmount.first != "$" {
            formattedAmount.insert("$", at: formattedAmount.startIndex)
        }

        // Trims to two decimal places
        guard let separatorIndex = formattedAmount.firstIndex(of: "."),
              let thirdDecimalIndex = formattedAmount.index(separatorIndex, offsetBy: 3, limitedBy: formattedAmount.endIndex) else {
            return formattedAmount
        }
        let unwantedDecimalsRange = thirdDecimalIndex..<formattedAmount.endIndex
        formattedAmount.removeSubrange(unwantedDecimalsRange)

        return formattedAmount
    }
}
