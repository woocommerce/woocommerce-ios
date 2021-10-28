import Foundation
import Yosemite

/// View Model for the `QuickOrderAmount` view.
///
final class QuickOrderAmountViewModel: ObservableObject {

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

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var presentNotice: Notice?

    /// Assign this closure to be notified when a new order is created
    ///
    var onOrderCreated: (Order) -> Void = { _ in }

    /// Returns true when amount has less than two characters.
    /// Less than two, because `$` should be the first character.
    ///
    var shouldDisableDoneButton: Bool {
        amount.count < 2
    }

    /// Dynamically builds the amount placeholder based on the store decimal separator.
    ///
    private(set) lazy var amountPlaceholder: String = {
        // TODO: We are appending the currency symbol always to the left, we should use `CurrencyFormatter` when releasing to more countries.
        storeCurrencySymbol + "0" + storeCurrencySettings.decimalSeparator + "00"
    }()

    /// Current store ID
    ///
    private let siteID: Int64

    /// Stores to dispatch actions
    ///
    private let stores: StoresManager

    /// Users locale, needed to use the correct decimal separator
    ///
    private let userLocale: Locale

    /// Current store currency settings
    ///
    private let storeCurrencySettings: CurrencySettings

    /// Current store currency symbol
    ///
    private let storeCurrencySymbol: String

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.userLocale = locale
        self.storeCurrencySettings = storeCurrencySettings
        self.storeCurrencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.analytics = analytics
    }

    /// Called when the view taps the done button.
    /// Creates a quick order order.
    ///
    func createQuickOrderOrder() {
        loading = true
        let action = OrderAction.createQuickOrderOrder(siteID: siteID, amount: amount) { [weak self] result in
            guard let self = self else { return }
            self.loading = false

            switch result {
            case .success(let order):
                self.onOrderCreated(order)
                self.analytics.track(event: WooAnalyticsEvent.QuickOrder.quickOrderFlowCompleted(amount: order.total))

            case .failure(let error):
                self.presentNotice = .error
                self.analytics.track(event: WooAnalyticsEvent.QuickOrder.quickOrderFlowFailed())
                DDLogError("⛔️ Error creating quick order order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow() {
        analytics.track(event: WooAnalyticsEvent.QuickOrder.quickOrderFlowCanceled())
    }
}

// MARK: Helpers
private extension QuickOrderAmountViewModel {

    /// Formats a received value by making sure the `$` symbol is present and trimming content to two decimal places.
    /// TODO: Update to support multiple currencies
    ///
    func formatAmount(_ amount: String) -> String {
        guard amount.isNotEmpty else { return amount }

        let deviceDecimalSeparator = userLocale.decimalSeparator ?? "."
        let storeDecimalSeparator = storeCurrencySettings.decimalSeparator

        // Removes any unwanted character & makes sure to use the store decimal separator
        var formattedAmount = amount
            .replacingOccurrences(of: deviceDecimalSeparator, with: storeDecimalSeparator)
            .filter { $0.isNumber || $0.isCurrencySymbol || "\($0)" == storeDecimalSeparator }

        // Prepend the store currency symbol if needed.
        // TODO: We are appending the currency symbol always to the left, we should use `CurrencyFormatter` when releasing to more countries.
        if !formattedAmount.hasPrefix(storeCurrencySymbol) {
            formattedAmount.insert(contentsOf: storeCurrencySymbol, at: formattedAmount.startIndex)
        }

        // Trim to two decimals & remove any extra "."
        let components = formattedAmount.components(separatedBy: storeDecimalSeparator)
        switch components.count {
        case 1 where formattedAmount.contains(storeDecimalSeparator):
            return components[0] + storeDecimalSeparator
        case 1:
            return components[0]
        case 2...Int.max:
            let number = components[0]
            let decimals = components[1]
            let trimmedDecimals = decimals.count > 2 ? "\(decimals.prefix(2))" : decimals
            return number + storeDecimalSeparator + trimmedDecimals
        default:
            fatalError("Should not happen, components can't be 0 or negative")
        }
    }
}

// MARK: Definitions
extension QuickOrderAmountViewModel {
    /// Representation of possible notices that can be displayed
    enum Notice: Equatable {
        case error
    }
}
