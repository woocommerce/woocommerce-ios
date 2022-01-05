import Foundation
import Yosemite
import Combine
import Experiments

/// View Model for the `SimplePaymentsAmount` view.
///
final class SimplePaymentsAmountViewModel: ObservableObject {

    /// Stores the amount(unformatted) entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = sanitizeAmount(amount)
            amountWithSymbol = setCurrencySymbol(to: amount)
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

    /// Formatted amount to display. When empty displays a placeholder value.
    ///
    var formattedAmmount: String {
        guard amount.isNotEmpty else {
            return amountPlaceholder
        }
        return amountWithSymbol
    }

    /// Defines the amount text color.
    ///
    var amountTextColor: UIColor {
        amount.isEmpty ? .textSubtle : .text
    }

    /// Returns true when the amount is not a positive number.
    ///
    var shouldDisableDoneButton: Bool {
        let decimalAmount = (currencyFormatter.convertToDecimal(from: amount) ?? .zero) as Decimal
        return decimalAmount <= .zero
    }

    /// Defines if the view actions should be disabled.
    /// Currently true while a network operation is happening.
    ///
    var disableViewActions: Bool {
        loading
    }

    /// Stores the formatted amount with the store currency symbol.
    ///
    private var amountWithSymbol: String = ""

    /// Dynamically builds the amount placeholder based on the store decimal separator.
    ///
    private lazy var amountPlaceholder: String = {
        currencyFormatter.formatAmount("0.00") ?? "$0.00"
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

    /// Currency formatter for the provided amount
    ///
    private let currencyFormatter: CurrencyFormatter

    /// Current store currency symbol
    ///
    private let storeCurrencySymbol: String

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         locale: Locale = Locale.autoupdatingCurrent,
         presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.userLocale = locale
        self.presentNoticeSubject = presentNoticeSubject
        self.storeCurrencySettings = storeCurrencySettings
        self.storeCurrencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.analytics = analytics
    }

    /// Called when the view taps the done button.
    /// Creates a simple payments order.
    ///
    func createSimplePaymentsOrder() {

        loading = true

        // Order created as taxable to delegate taxes calculation to the API.
        let action = OrderAction.createSimplePaymentsOrder(siteID: siteID, amount: amount, taxable: true) { [weak self] result in
            guard let self = self else { return }
            self.loading = false

            switch result {
            case .success(let order):
                self.summaryViewModel = SimplePaymentsSummaryViewModel(order: order,
                                                                       providedAmount: self.amount,
                                                                       presentNoticeSubject: self.presentNoticeSubject)

            case .failure(let error):
                self.presentNoticeSubject.send(.error(Localization.creationError))
                self.analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowFailed(source: .amount))
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

    /// Formats a received value by sanitizing the input and trimming content to two decimal places.
    ///
    func sanitizeAmount(_ amount: String) -> String {
        guard amount.isNotEmpty else { return amount }

        let deviceDecimalSeparator = userLocale.decimalSeparator ?? "."
        let storeDecimalSeparator = storeCurrencySettings.decimalSeparator
        let storeNumberOfDecimals = storeCurrencySettings.numberOfDecimals

        // Removes any unwanted character & makes sure to use the store decimal separator
        let sanitized = amount
            .replacingOccurrences(of: deviceDecimalSeparator, with: storeDecimalSeparator)
            .filter { $0.isNumber || "\($0)" == storeDecimalSeparator }

        // Trim to two decimals & remove any extra "."
        let components = sanitized.components(separatedBy: storeDecimalSeparator)
        switch components.count {
        case 1 where sanitized.contains(storeDecimalSeparator):
            return components[0] + storeDecimalSeparator
        case 1:
            return components[0]
        case 2...Int.max:
            let number = components[0]
            let decimals = components[1]
            let trimmedDecimals = decimals.count > storeNumberOfDecimals ? "\(decimals.prefix(storeNumberOfDecimals))" : decimals
            return number + storeDecimalSeparator + trimmedDecimals
        default:
            fatalError("Should not happen, components can't be 0 or negative")
        }
    }

    /// Formats a received value by adding the store currency symbol to it's correct position.
    ///
    func setCurrencySymbol(to amount: String) -> String {
        currencyFormatter.formatCurrency(using: amount,
                                         at: storeCurrencySettings.currencyPosition,
                                         with: storeCurrencySymbol,
                                         isNegative: false)
    }
}

// MARK: Constants
private extension SimplePaymentsAmountViewModel {
    enum Localization {
        static let creationError = NSLocalizedString("There was an error creating the order",
                                                     comment: "Notice text after failing to create a simple payments order.")
    }
}
