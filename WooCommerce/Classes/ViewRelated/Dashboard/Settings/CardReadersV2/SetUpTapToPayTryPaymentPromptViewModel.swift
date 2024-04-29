import Foundation
import Yosemite
import Combine
import WooFoundation

final class SetUpTapToPayTryPaymentPromptViewModel: PaymentSettingsFlowPresentedViewModel, ObservableObject {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?
    var dismiss: (() -> Void)?

    @Published var paymentFlowFinished: Bool = false

    @Published var refundInProgress: Bool = false

    @Published var shouldShowTrialOrderDetails: Bool = false

    private(set) var connectedReader: CardReaderSettingsTriState = .isUnknown {
        didSet {
            didUpdate?()
        }
    }

    private let connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker
    private let stores: StoresManager

    @Published var loading: Bool = false

    var summaryViewModel: TryAPaymentSummaryViewModel? = nil
    @Published var summaryActive: Bool = false

    @Published var formattedPaymentAmount: String = ""

    private let presentNoticeSubject: PassthroughSubject<PaymentMethodsNotice, Never> = PassthroughSubject()
    private let analytics: Analytics = ServiceLocator.analytics
    private let configuration: CardPresentPaymentsConfiguration

    private var subscriptions = Set<AnyCancellable>()

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    private let currencyFormatter: CurrencyFormatter
    private let currencySettings: CurrencySettings
    private let trialPaymentAmount: String

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?,
         connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.didChangeShouldShow = didChangeShouldShow
        self.connectionAnalyticsTracker = connectionAnalyticsTracker
        self.configuration = configuration
        self.stores = stores
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.currencyFormatter = currencyFormatter
        self.currencySettings = currencySettings
        self.trialPaymentAmount = currencyFormatter.formatAmount(configuration.minimumAllowedChargeAmount) ?? "0.50"

        beginConnectedReaderObservation()
        updateFormattedPaymentAmount()
        observePaymentFlowFinishedToAttemptRefund()
    }

    /// Called when the user dismisses the prompt view.
    func onDismiss() {
        analytics.track(event: WooAnalyticsEvent.PaymentsFlow
            .paymentsFlowCanceled(flow: .tapToPayTryAPayment,
                                  country: configuration.countryCode,
                                  currency: currencySettings.currencyCode.rawValue))
        dismiss?()
    }

    /// Set up to observe readers connecting / disconnecting
    ///
    private func beginConnectedReaderObservation() {
        // This completion should be called repeatedly as the list of connected readers changes
        let connectedAction = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.connectedReader = readers.isNotEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        stores.dispatch(connectedAction)
    }

    private func updateFormattedPaymentAmount() {
        let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        guard let formattedAmount = currencyFormatter.formatAmount(trialPaymentAmount,
                                                                   with: configuration.currencies.first?.rawValue) else {
            return
        }
        formattedPaymentAmount = formattedAmount
    }

    private func startTestPayment() {
        loading = true
        let action = OrderAction.createSimplePaymentsOrder(siteID: siteID,
                                                           status: .pending,
                                                           amount: trialPaymentAmount,
                                                           taxable: false) { [weak self] result in
            guard let self = self else { return }
            self.loading = false

            switch result {
            case .success(let order):
                self.summaryViewModel = TryAPaymentSummaryViewModel(
                    simplePaymentSummaryViewModel: SimplePaymentsSummaryViewModel(order: order,
                                                                                  providedAmount: order.total,
                                                                                  presentNoticeSubject: self.presentNoticeSubject,
                                                                                  analyticsFlow: .tapToPayTryAPayment),
                    siteID: self.siteID,
                    order: order)
                self.summaryActive = true


            case .failure(let error):
                self.presentNoticeSubject.send(.error(Localization.errorCreatingTestPayment))
                self.analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowFailed(flow: .tapToPayTryAPayment,
                                                                                              source: .tapToPayTryAPaymentPrompt,
                                                                                              country: configuration.countryCode,
                                                                                              currency: currencySettings.currencyCode.rawValue))

                DDLogError("⛔️ Error creating Tap to Pay try a payment order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    private func observePaymentFlowFinishedToAttemptRefund() {
        $paymentFlowFinished
            .share()
            .filter { $0 == true }
            .sink { [weak self] _ in
                guard let self else { return }
                guard let summaryViewModel else { return }
                self.refundInProgress = true
                let refundableOrderItems = summaryViewModel.order.items.map { RefundableOrderItem(item: $0, quantity: $0.quantity) }
                let refundUseCase = RefundCreationUseCase(amount: summaryViewModel.order.total,
                                                          reason: Localization.paymentRefundReason,
                                                          automaticallyRefundsPayment: true,
                                                          items: refundableOrderItems,
                                                          shippingLine: summaryViewModel.order.shippingLines.first,
                                                          fees: summaryViewModel.order.fees,
                                                          currencyFormatter: CurrencyFormatter(currencySettings: ServiceLocator.currencySettings))
                let refund = refundUseCase.createRefund()
                let refundAction = RefundAction.createRefund(siteID: siteID,
                                                             orderID: summaryViewModel.orderID,
                                                             refund: refund) { [weak self] refund, error in
                    guard let self = self else { return }
                    defer {
                        self.refundInProgress = false
                    }
                    if let error {
                        self.shouldShowTrialOrderDetails = true
                        analytics.track(event: .init(statName: .tapToPayAutoRefundFailed, properties: [:], error: error))
                        return DDLogError("Could not refund Tap to Pay trial payment: \(error)")
                    }
                    guard refund != nil else {
                        self.shouldShowTrialOrderDetails = true
                        analytics.track(.tapToPayAutoRefundFailed)
                        return DDLogError("Unexpected response when refunding Tap to Pay trial payment for order: \(summaryViewModel.orderID)")
                    }
                    analytics.track(.tapToPayAutoRefundSuccess)
                    self.dismiss?()
                    ServiceLocator.noticePresenter.enqueue(
                        notice: Notice(title: Localization.paymentRefundNoticeTitle,
                                       message: Localization.paymentRefundNoticeMessage))
                }
                stores.dispatch(refundAction)
            }
            .store(in: &subscriptions)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifies the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        let newShouldShow: CardReaderSettingsTriState = connectedReader

        let didChange = newShouldShow != shouldShow

        if didChange {
            shouldShow = newShouldShow
            didChangeShouldShow?(shouldShow)
        }
    }

    func tryAPaymentTapped() {
        analytics.track(.tapToPaySummaryTryPaymentTapped)
        startTestPayment()
    }

    func skipTapped() {
        analytics.track(.tapToPaySummaryTryPaymentSkipTapped)
        dismiss?()
    }

    func onAppear() {
        analytics.track(.tapToPaySummaryShown)
    }

    func onTrialPaymentFlowFinished() {
        summaryActive = false
        paymentFlowFinished = true
    }

    deinit {
        subscriptions.removeAll()
    }
}

extension SetUpTapToPayTryPaymentPromptViewModel {
    enum Localization {
        static let errorCreatingTestPayment = NSLocalizedString(
            "The trial payment could not be started, please try again, or contact support if this problem persists.",
            comment: "Error notice shown when the try a payment option in Set up Tap to Pay on iPhone fails.")

        static let paymentRefundNoticeTitle = NSLocalizedString(
                    "tap.to.pay.try.payment.refundNotice.success.title",
                    value: "Tap to Pay Trial Payment",
                    comment: "After a trial Tap to Pay payment, we attempt to automatically refund the test amount. When " +
                    "this is successful, we show a Notice to alert the user – this is the title of the notice.")

        static let paymentRefundNoticeMessage = NSLocalizedString(
                    "tap.to.pay.try.payment.refundNotice.success.message",
                    value: "Trial Tap to Pay payment was successfully refunded.",
                    comment: "After a trial Tap to Pay payment, we attempt to automatically refund the test amount. When " +
                    "this is successful, we show a Notice to alert the user – this is the body of the notice.")

        static let paymentRefundReason = NSLocalizedString(
            "tap.to.pay.try.payment.refund.reason",
            value: "Trial Tap to Pay payment auto refund",
            comment: "After a trial Tap to Pay payment, we attempt to automatically refund the test amount. When " +
            "this is sent to the server, we provide a reason for later identification.")
    }
}

struct TryAPaymentSummaryViewModel {
    let simplePaymentSummaryViewModel: SimplePaymentsSummaryViewModel
    let siteID: Int64
    let order: Order

    var orderID: Int64 {
        order.orderID
    }
}
