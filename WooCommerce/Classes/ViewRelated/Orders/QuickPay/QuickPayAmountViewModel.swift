import Foundation
import Yosemite

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

    /// True while performing the create order operation. False otherwise.
    ///
    @Published private(set) var loading: Bool = false

    /// Returns true when amount has less than two characters.
    /// Less than two, because `$` should be the first character.
    ///
    var shouldDisableDoneButton: Bool {
        amount.count < 2
    }

    /// Current store ID
    ///
    private let siteID: Int64

    /// Stores to dispatch actions
    ///
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Called when the view taps the done button.
    /// Creates a quick pay order.
    ///
    func createQuickPayOrder() {
        loading = true
        let action = OrderAction.createQuickPayOrder(siteID: siteID, amount: amount) { [weak self] result in
            self?.loading = false

            switch result {
            case .success:
                break
                // TODO: Inform about completion

            case .failure(let error):
                DDLogError("⛔️ Error creating quick pay order: \(error)")
                // TODO: Show error notice
                // TODO: Inform about completion
            }
        }
        stores.dispatch(action)
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

        // Trim to two decimals & remove any extra "."
        let components = formattedAmount.split(separator: ".")
        switch components.count {
        case 1 where formattedAmount.contains("."):
            return components[0] + "."
        case 1:
            return "\(components[0])"
        case 2...Int.max:
            let number = components[0]
            let decimals = components[1]
            let trimmedDecimals = decimals.count > 2 ? decimals.prefix(2) : decimals
            return "\(number).\(trimmedDecimals)"
        default:
            fatalError("Should not happen, components can't be 0 or negative")
        }
    }
}
