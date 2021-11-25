import Foundation
import Yosemite
import Combine
import Experiments

/// View Model for the `SimplePaymentsAmount` view.
///
final class SimplePaymentsAmountViewModel: ObservableObject {

    /// Stores the amount(formatted) entered by the merchant.
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

    /// Defines if the view should navigate to the summary view.
    /// Setting it to `false` will `nil` the summary view model.
    ///
    @Published var navigateToSummary: Bool = false {
        didSet {
            if !navigateToSummary && oldValue != navigateToSummary {
                summaryViewModel = nil
            }
        }
    }

    /// Assign this closure to be notified when a new order is created
    ///
    var onOrderCreated: (Order) -> Void = { _ in }

    /// Returns true when amount has less than two characters.
    /// Less than two, because `$` should be the first character.
    ///
    var shouldDisableDoneButton: Bool {
        amount.count < 2
    }

    /// Use this to disables interactive dismissal and
    /// Disables cancel button while performing the create order operation
    ///
    var disableCancel: Bool {
        loading
    }

    /// Dynamically builds the amount placeholder based on the store decimal separator.
    ///
    private(set) lazy var amountPlaceholder: String = {
        // TODO: We are appending the currency symbol always to the left, we should use `CurrencyFormatter` when releasing to more countries.
        storeCurrencySymbol + "0" + storeCurrencySettings.decimalSeparator + "00"
    }()

    /// Retains the SummaryViewModel.
    /// Assigning it will set `navigateToSummary`.
    ///
    private(set) var summaryViewModel: SimplePaymentsSummaryViewModel? {
        didSet {
            navigateToSummary = summaryViewModel != nil
        }
    }

    /// Current store ID
    ///
    private let siteID: Int64

    /// Stores to dispatch actions
    ///
    private let stores: StoresManager

    /// Users locale, needed to use the correct decimal separator
    ///
    private let userLocale: Locale

    /// Transmits notice presentation intents.
    ///
    private let presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never>

    /// Current store currency settings
    ///
    private let storeCurrencySettings: CurrencySettings

    /// Current store currency symbol
    ///
    private let storeCurrencySymbol: String

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    /// Defines if the we are running a development version or not.
    ///
    private let isDevelopmentPrototype: Bool

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         locale: Locale = Locale.autoupdatingCurrent,
         presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         isDevelopmentPrototype: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(FeatureFlag.simplePaymentsPrototype)) {
        self.siteID = siteID
        self.stores = stores
        self.userLocale = locale
        self.presentNoticeSubject = presentNoticeSubject
        self.storeCurrencySettings = storeCurrencySettings
        self.storeCurrencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.analytics = analytics
        self.isDevelopmentPrototype = isDevelopmentPrototype
    }

    /// Called when the view taps the done button.
    /// Creates a simple payments order.
    ///
    func createSimplePaymentsOrder() {

        loading = true

        // Prototype in production does not support taxes. Development version does.
        let action = OrderAction.createSimplePaymentsOrder(siteID: siteID, amount: amount, taxable: isDevelopmentPrototype) { [weak self] result in
            guard let self = self else { return }
            self.loading = false

            switch result {
            case .success(let order):
                if self.isDevelopmentPrototype {
                    self.summaryViewModel = SimplePaymentsSummaryViewModel(order: order, providedAmount: self.amount)
                } else {
                    self.onOrderCreated(order)
                }
                self.analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowCompleted(amount: order.total))

            case .failure(let error):
                self.presentNoticeSubject.send(.error(Localization.creationError))
                self.analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowFailed())
                DDLogError("⛔️ Error creating simple payments order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow() {
        analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowCanceled())
    }
}

// MARK: Helpers
private extension SimplePaymentsAmountViewModel {

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

// MARK: Constants
private extension SimplePaymentsAmountViewModel {
    enum Localization {
        static let creationError = NSLocalizedString("There was an error creating the order",
                                                     comment: "Notice text after failing to create a simple payments order.")
    }
}
