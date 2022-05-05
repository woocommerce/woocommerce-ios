import Experiments
import Foundation
import Yosemite
import Combine
import UIKit

import protocol Storage.StorageManagerType

/// ViewModel for the `SimplePaymentsMethods` view.
///
final class SimplePaymentsMethodsViewModel: ObservableObject {

    /// Navigation bar title.
    ///
    let title: String

    /// Defines if the view should show a card payment method.
    ///
    @Published private(set) var showPayWithCardRow = false

    /// Allows the onboarding flow to be presented before a card present payment when required
    ///
    private let cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting

    /// Defines if the view should show a loading indicator.
    /// Currently set while marking the order as complete
    ///
    @Published private(set) var showLoadingIndicator = false

    /// Stores the payment link for the order.
    ///
    let paymentLink: URL?

    /// Defines if the view should be disabled to prevent any further action.
    /// Useful to prevent any double tap while a network operation is being performed.
    ///
    var disableViewActions: Bool {
        showLoadingIndicator
    }

    /// Defines if the view should show a payment link payment method.
    ///
    var showPaymentLinkRow: Bool {
        paymentLink != nil
    }

    /// Store's ID.
    ///
    private let siteID: Int64

    /// Order's ID to update
    ///
    private let orderID: Int64

    /// Formatted total to charge.
    ///
    private let formattedTotal: String

    /// Transmits notice presentation intents.
    ///
    private let presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never>

    /// Observes the store's current CPP state.
    ///
    private let cppStoreStateObserver: CardPresentPaymentsOnboardingUseCaseProtocol

    /// Store manager to update order.
    ///
    private let stores: StoresManager

    /// Storage manager to fetch the order.
    ///
    private let storage: StorageManagerType

    /// Tracks analytics events.
    ///
    private let analytics: Analytics

    /// Stored payment gateways accounts.
    /// We will care about the first one because only one is supported right now.
    ///
    private lazy var gatewayAccountResultsController: ResultsController<StoragePaymentGatewayAccount> = {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let controller = ResultsController<StoragePaymentGatewayAccount>(storageManager: storage, matching: predicate, sortedBy: [])
        try? controller.performFetch()
        return controller
    }()

    /// Stored orders.
    /// We need to fetch this from our storage layer because we are only provide IDs as dependencies
    /// To keep previews/UIs decoupled from our business logic.
    ///
    private lazy var ordersResultController: ResultsController<StorageOrder> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld", siteID, orderID)
        let controller = ResultsController<StorageOrder>(storageManager: storage, matching: predicate, sortedBy: [])
        try? controller.performFetch()
        return controller
    }()

    /// Retains the use-case so it can perform all of its async tasks.
    ///
    private var collectPaymentsUseCase: CollectOrderPaymentProtocol?

    struct Dependencies {
        let presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never>
        let cppStoreStateObserver: CardPresentPaymentsOnboardingUseCaseProtocol
        let cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting
        let stores: StoresManager
        let storage: StorageManagerType
        let analytics: Analytics

        init(presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
             cppStoreStateObserver: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase(),
             cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting = CardPresentPaymentsOnboardingPresenter(),
             stores: StoresManager = ServiceLocator.stores,
             storage: StorageManagerType = ServiceLocator.storageManager,
             analytics: Analytics = ServiceLocator.analytics) {
            self.presentNoticeSubject = presentNoticeSubject
            self.cppStoreStateObserver = cppStoreStateObserver
            self.cardPresentPaymentsOnboardingPresenter = cardPresentPaymentsOnboardingPresenter
            self.stores = stores
            self.storage = storage
            self.analytics = analytics
        }
    }

    init(siteID: Int64 = 0,
         orderID: Int64 = 0,
         paymentLink: URL? = nil,
         formattedTotal: String,
         dependencies: Dependencies = Dependencies()) {
        self.siteID = siteID
        self.orderID = orderID
        self.paymentLink = paymentLink
        self.formattedTotal = formattedTotal
        presentNoticeSubject = dependencies.presentNoticeSubject
        cppStoreStateObserver = dependencies.cppStoreStateObserver
        cardPresentPaymentsOnboardingPresenter = dependencies.cardPresentPaymentsOnboardingPresenter
        stores = dependencies.stores
        storage = dependencies.storage
        analytics = dependencies.analytics
        title = String(format: Localization.title, formattedTotal)

        bindStoreCPPState()
    }

    /// Creates the info text when the merchant selects the cash payment method.
    ///
    func payByCashInfo() -> String {
        Localization.markAsPaidInfo(total: formattedTotal)
    }

    /// Mark an order as paid and notify if successful.
    ///
    func markOrderAsPaid(onSuccess: @escaping () -> ()) {
        showLoadingIndicator = true
        let action = OrderAction.updateOrderStatus(siteID: siteID, orderID: orderID, status: .completed) { [weak self] error in
            guard let self = self else { return }
            self.showLoadingIndicator = false

            if let error = error {
                self.presentNoticeSubject.send(.error(Localization.markAsPaidError))
                self.trackFlowFailed()
                return DDLogError("⛔️ Error updating simple payments order: \(error)")
            }

            onSuccess()
            self.presentNoticeSubject.send(.completed)
            self.trackFlowCompleted(method: .cash)
        }
        stores.dispatch(action)
    }

    /// Starts the collect payment flow in the provided `rootViewController`
    /// - parameter useCase: Assign a custom useCase object for testing purposes. If not provided `CollectOrderPaymentUseCase` will be used.
    ///
    func collectPayment(on rootViewController: UIViewController?,
                        useCase: CollectOrderPaymentProtocol? = nil,
                        onSuccess: @escaping () -> ()) {
        trackCollectIntention(method: .card)

        guard let rootViewController = rootViewController else {
            DDLogError("⛔️ Root ViewController is nil, can't present payment alerts.")
            return presentNoticeSubject.send(.error(Localization.genericCollectError))
        }

        cardPresentPaymentsOnboardingPresenter.showOnboardingIfRequired(
            from: rootViewController) { [weak self] in
                guard let self = self else { return }

                guard let order = self.ordersResultController.fetchedObjects.first else {
                    DDLogError("⛔️ Order not found, can't collect payment.")
                    return self.presentNoticeSubject.send(.error(Localization.genericCollectError))
                }

                guard let paymentGateway = self.gatewayAccountResultsController.fetchedObjects.first else {
                    DDLogError("⛔️ Payment Gateway not found, can't collect payment.")
                    return self.presentNoticeSubject.send(.error(Localization.genericCollectError))
                }

                self.collectPaymentsUseCase = useCase ?? CollectOrderPaymentUseCase(
                    siteID: self.siteID,
                    order: order,
                    formattedAmount: self.formattedTotal,
                    paymentGatewayAccount: paymentGateway,
                    rootViewController: rootViewController,
                    alerts: OrderDetailsPaymentAlerts(transactionType: .collectPayment,
                                                      presentingController: rootViewController),
                    configuration: CardPresentConfigurationLoader().configuration)

                self.collectPaymentsUseCase?.collectPayment(
                    backButtonTitle: Localization.continueToOrders,
                    onCollect: { [weak self] result in
                        if result.isFailure {
                            self?.trackFlowFailed()
                        }
                    },
                    onCompleted: { [weak self] in
                        // Inform success to consumer
                        onSuccess()

                        // Sent notice request
                        self?.presentNoticeSubject.send(.completed)

                        // Make sure we free all the resources
                        self?.collectPaymentsUseCase = nil

                        // Tracks completion
                        self?.trackFlowCompleted(method: .card)
                    })
            }
    }

    /// Tracks the collect by cash intention.
    ///
    func trackCollectByCash() {
        trackCollectIntention(method: .cash)
    }

    func trackCollectByPaymentLink() {
        trackCollectIntention(method: .paymentLink)
    }

    /// Perform the necesary tasks after a link is shared.
    ///
    func performLinkSharedTasks() {
        presentNoticeSubject.send(.created)
        trackFlowCompleted(method: .paymentLink)
    }
}

// MARK: Helpers
private extension SimplePaymentsMethodsViewModel {

    /// Observes the store CPP state and update publish variables accordingly.
    ///
    func bindStoreCPPState() {
        cppStoreStateObserver
            .statePublisher
            .map { $0.isCompleted }
            .removeDuplicates()
            .assign(to: &$showPayWithCardRow)
        cppStoreStateObserver.refresh()
    }

    /// Tracks the `simplePaymentsFlowCompleted` event.
    ///
    func trackFlowCompleted(method: WooAnalyticsEvent.SimplePayments.PaymentMethod) {
        analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowCompleted(amount: formattedTotal, method: method))
    }

    /// Tracks the `simplePaymentsFlowFailed` event.
    ///
    func trackFlowFailed() {
        analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowFailed(source: .paymentMethod))
    }

    /// Tracks `simplePaymentsFlowCollect` event.
    ///
    func trackCollectIntention(method: WooAnalyticsEvent.SimplePayments.PaymentMethod) {
        analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowCollect(method: method))
    }
}

private extension SimplePaymentsMethodsViewModel {
    enum Localization {
        static let markAsPaidError = NSLocalizedString("There was an error while marking the order as paid.",
                                                       comment: "Text when there is an error while marking the order as paid for simple payments.")
        static let genericCollectError = NSLocalizedString("There was an error while trying to collect the payment.",
                                                       comment: "Text when there is an unknown error while trying to collect payments")
        static let continueToOrders = NSLocalizedString("Continue To Orders",
                                                        comment: "Button to dismiss modal overlay and go back to the orders list after a sucessful payment")

        static let title = NSLocalizedString("Take Payment (%1$@)",
                                             comment: "Navigation bar title for the Simple Payments Methods screens. " +
                                             "%1$@ is a placeholder for the total amount to collect")

        static func markAsPaidInfo(total: String) -> String {
            NSLocalizedString("This will mark your order as complete if you received \(total) outside of WooCommerce",
                              comment: "Alert info when selecting the cash payment method for simple payments")
        }
    }
}
