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

    /// Users locale, needed to use the correct decimal separator
    ///
    private let userLocale: Locale

    init(locale: Locale = Locale.autoupdatingCurrent) {
        self.userLocale = locale
    }
}

// MARK: Helpers
private extension QuickPayAmountViewModel {

    /// Formats a received value by making sure the `$` symbol is present and trimming content to two decimal places.
    /// TODO: Update to support multiple currencies
    ///
    func formatAmount(_ amount: String) -> String {
        guard amount.isNotEmpty else { return amount }

        // Removes any unwanted character
        let separatorCharacter = userLocale.decimalSeparator ?? "."
        var formattedAmount = amount.filter { $0.isNumber || $0.isCurrencySymbol || "\($0)" == separatorCharacter }

        // Prepend the `$` symbol if needed.
        if formattedAmount.first != "$" {
            formattedAmount.insert("$", at: formattedAmount.startIndex)
        }

        // Trim to two decimals & remove any extra "."
        let components = formattedAmount.components(separatedBy: separatorCharacter)
        switch components.count {
        case 1 where formattedAmount.contains(separatorCharacter):
            return components[0] + separatorCharacter
        case 1:
            return components[0]
        case 2...Int.max:
            let number = components[0]
            let decimals = components[1]
            let trimmedDecimals = decimals.count > 2 ? "\(decimals.prefix(2))" : decimals
            return number + separatorCharacter + trimmedDecimals
        default:
            fatalError("Should not happen, components can't be 0 or negative")
        }
    }
}
