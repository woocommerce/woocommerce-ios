import Foundation
import Yosemite
import Combine
import Experiments
import WooFoundation

/// View Model for the `SimplePaymentsAmount` view.
///
final class SimplePaymentsAmountViewModel: ObservableObject {
    let formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel

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

    @Published var shouldDisableDoneButton: Bool = true

    /// Defines if the view actions should be disabled.
    /// Currently true while a network operation is happening.
    ///
    var disableViewActions: Bool {
        loading
    }

    /// Defines if the swipe-to-dismiss gesture on the Simple Payment flow should be enabled
    ///
    var shouldEnableSwipeToDismiss: Bool {
        (!formattableAmountTextFieldViewModel.amountIsValid) &&
        !loading
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

    lazy var presentNoticePublisher: AnyPublisher<SimplePaymentsNotice, Never> = {
        presentNoticeSubject.eraseToAnyPublisher()
    }()

    /// Defines the status for a new simple payments order. `auto-draft` for new stores. `pending` for old stores.
    ///
    private var initialOrderStatus: OrderStatusEnum = .pending

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
        self.formattableAmountTextFieldViewModel = FormattableAmountTextFieldViewModel(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.presentNoticeSubject = presentNoticeSubject
        self.analytics = analytics

        updateInitialOrderStatus()
        listenToAmountChanges()
    }

    /// Called when the view taps the done button.
    /// Creates a simple payments order.
    ///
    func createSimplePaymentsOrder() {
        loading = true

        // Order created as taxable to delegate taxes calculation to the API.
        let action = OrderAction.createSimplePaymentsOrder(siteID: siteID,
                                                           status: initialOrderStatus,
                                                           amount: formattableAmountTextFieldViewModel.amount, taxable: true) { [weak self] result in
            guard let self = self else { return }
            self.loading = false

            switch result {
            case .success(let order):
                self.summaryViewModel = SimplePaymentsSummaryViewModel(order: order,
                                                                       providedAmount: formattableAmountTextFieldViewModel.amount,
                                                                       presentNoticeSubject: self.presentNoticeSubject)

            case .failure(let error):
                self.presentNoticeSubject.send(.error(Localization.creationError))
                self.analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowFailed(flow: .simplePayment, source: .amount))
                DDLogError("⛔️ Error creating simple payments order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow() {
        analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowCanceled(flow: .simplePayment))
    }


}

private extension SimplePaymentsAmountViewModel {
    /// Updates the initial order status.
    ///
    func updateInitialOrderStatus() {
        NewOrderInitialStatusResolver(siteID: siteID, stores: stores).resolve { [weak self] baseStatus in
            self?.initialOrderStatus = baseStatus
        }
    }

    func listenToAmountChanges() {
        formattableAmountTextFieldViewModel.$amount.map { _ in
            !self.formattableAmountTextFieldViewModel.amountIsValid
        }.assign(to: &$shouldDisableDoneButton)
    }
}

// MARK: Constants
private extension SimplePaymentsAmountViewModel {
    enum Localization {
        static let creationError = NSLocalizedString("There was an error creating the order",
                                                     comment: "Notice text after failing to create a simple payments order.")
    }
}
