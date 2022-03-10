import Foundation
import Yosemite
import Combine
import Experiments

/// View Model for the `SimplePaymentsAmount` view.
///
final class SimplePaymentsAmountViewModel: ObservableObject {

    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter

    /// Stores the amount(unformatted) entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = priceFieldFormatter.formatAmount(amount)
        }
    }

    /// Formatted amount to display. When empty displays a placeholder value.
    ///
    var formattedAmount: String {
        priceFieldFormatter.formattedAmount
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

    /// Defines the amount text color.
    ///
    var amountTextColor: UIColor {
        amount.isEmpty ? .textSubtle : .text
    }

    /// Returns true when the amount is not a positive number.
    ///
    var shouldDisableDoneButton: Bool {
        guard let amountDecimal = priceFieldFormatter.amountDecimal else {
            return true
        }

        return amountDecimal <= .zero
    }

    /// Defines if the view actions should be disabled.
    /// Currently true while a network operation is happening.
    ///
    var disableViewActions: Bool {
        loading
    }

    /// Defines if the swipe-to-dismiss gesture on the Simple Payment flow should be disabled
    ///
    var disablesSwipeToDismiss: Bool {
        summaryViewModel != nil && summaryViewModel?.navigateToPaymentMethods != true
    }

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

    /// Transmits notice presentation intents.
    ///
    private let presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never>

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
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.presentNoticeSubject = presentNoticeSubject
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

// MARK: Constants
private extension SimplePaymentsAmountViewModel {
    enum Localization {
        static let creationError = NSLocalizedString("There was an error creating the order",
                                                     comment: "Notice text after failing to create a simple payments order.")
    }
}
