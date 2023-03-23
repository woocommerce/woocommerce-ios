import Foundation
import Yosemite
import Combine

final class SetUpTapToPayTryPaymentPromptViewModel: PaymentSettingsFlowPresentedViewModel, ObservableObject {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?
    var dismiss: (() -> Void)?

    private(set) var connectedReader: CardReaderSettingsTriState = .isUnknown {
        didSet {
            didUpdate?()
        }
    }

    private let connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker
    private let stores: StoresManager

    @Published var loading: Bool = false
    var summaryViewModel: TryAPaymentSummaryViewModel? = nil {
        didSet {
            summaryActive = summaryViewModel != nil
        }
    }
    @Published var summaryActive: Bool = false

    private let presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject()
    private let analytics: Analytics = ServiceLocator.analytics

    private var subscriptions = Set<AnyCancellable>()

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?,
         connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker,
         stores: StoresManager = ServiceLocator.stores) {
        self.didChangeShouldShow = didChangeShouldShow
        self.connectionAnalyticsTracker = connectionAnalyticsTracker
        self.stores = stores

        beginConnectedReaderObservation()
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

    private func startTestPayment() {
        loading = true
        let action = OrderAction.createSimplePaymentsOrder(siteID: siteID,
                                                           status: .pending,
                                                           amount: Constants.tapToPayTryAPaymentAmount,
                                                           taxable: false) { [weak self] result in
            guard let self = self else { return }
            self.loading = false

            switch result {
            case .success(let order):
                self.summaryViewModel = TryAPaymentSummaryViewModel(
                    simplePaymentSummaryViewModel: SimplePaymentsSummaryViewModel(order: order,
                                                                                  providedAmount: order.total,
                                                                                  presentNoticeSubject: self.presentNoticeSubject),
                    siteID: self.siteID,
                    orderID: order.orderID)


            case .failure(let error):
                self.presentNoticeSubject.send(.error(Localization.errorCreatingTestPayment))
                self.analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowFailed(flow: .tapToPayTryAPayment,
                                                                                              source: .tapToPayTryAPaymentPrompt))
                DDLogError("⛔️ Error creating Tap to Pay try a payment order: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifies the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        let newShouldShow: CardReaderSettingsTriState = connectedReader

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
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

    deinit {
        subscriptions.removeAll()
    }
}

extension SetUpTapToPayTryPaymentPromptViewModel {
    enum Constants {
        static let tapToPayTryAPaymentAmount = "0.50"
    }

    enum Localization {
        static let errorCreatingTestPayment = NSLocalizedString(
            "The trial payment could not be started, please try again, or contact support if this problem persists.",
            comment: "Error notice shown when the try a payment option in Set up Tap to Pay on iPhone fails.")
    }
}

struct TryAPaymentSummaryViewModel {
    let simplePaymentSummaryViewModel: SimplePaymentsSummaryViewModel
    let siteID: Int64
    let orderID: Int64
}
