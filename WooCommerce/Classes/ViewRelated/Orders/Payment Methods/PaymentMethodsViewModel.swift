import Foundation
import Yosemite
import Combine
import UIKit
import WooFoundation

import protocol Storage.StorageManagerType

/// ViewModel for the `PaymentsMethodsView`
///
final class PaymentMethodsViewModel: ObservableObject {

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

    /// Defines if the Card Reader upsell banner should be shown based on country eligibility and dismissal/reminder preferences
    ///
    @Published var showUpsellCardReaderFeatureBanner: Bool

    /// Returns the URL where the merchant can purchase a card reader based on store country code
    ///
    var purchaseCardReaderUrl: URL {
        cardPresentPaymentsConfiguration.purchaseCardReaderUrl(utmProvider: upsellCardReadersCampaign.utmProvider)
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

    /// Store manager to update order.
    ///
    private let stores: StoresManager

    /// Storage manager to fetch the order.
    ///
    private let storage: StorageManagerType

    /// Tracks analytics events.
    ///
    private let analytics: Analytics

    /// Defines the flow to be reported in Analytics
    ///
    private let flow: WooAnalyticsEvent.PaymentsFlow.Flow

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
    private var legacyCollectPaymentsUseCase: LegacyCollectOrderPaymentProtocol?

    private var collectPaymentsUseCase: CollectOrderPaymentProtocol?

    private let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    private let upsellCardReadersCampaign = UpsellCardReadersCampaign(source: .paymentMethods)

    var upsellCardReadersAnnouncementViewModel: FeatureAnnouncementCardViewModel {
        .init(analytics: analytics,
              configuration: upsellCardReadersCampaign.configuration)
    }

    private let isTapToPayOnIPhoneEnabled: Bool

    struct Dependencies {
        let presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never>
        let cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting
        let stores: StoresManager
        let storage: StorageManagerType
        let analytics: Analytics
        let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

        init(presentNoticeSubject: PassthroughSubject<SimplePaymentsNotice, Never> = PassthroughSubject(),
             cardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting = CardPresentPaymentsOnboardingPresenter(),
             stores: StoresManager = ServiceLocator.stores,
             storage: StorageManagerType = ServiceLocator.storageManager,
             analytics: Analytics = ServiceLocator.analytics,
             cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration? = nil) {
            self.presentNoticeSubject = presentNoticeSubject
            self.cardPresentPaymentsOnboardingPresenter = cardPresentPaymentsOnboardingPresenter
            self.stores = stores
            self.storage = storage
            self.analytics = analytics
            let configuration = cardPresentPaymentsConfiguration ?? CardPresentConfigurationLoader(stores: stores).configuration
            self.cardPresentPaymentsConfiguration = configuration
        }
    }

    init(siteID: Int64 = 0,
         orderID: Int64 = 0,
         paymentLink: URL? = nil,
         formattedTotal: String,
         flow: WooAnalyticsEvent.PaymentsFlow.Flow,
         isTapToPayOnIPhoneEnabled: Bool = ServiceLocator.generalAppSettings.settings.isTapToPayOnIPhoneSwitchEnabled,
         dependencies: Dependencies = Dependencies()) {
        self.siteID = siteID
        self.orderID = orderID
        self.paymentLink = paymentLink
        self.formattedTotal = formattedTotal
        self.flow = flow
        self.isTapToPayOnIPhoneEnabled = isTapToPayOnIPhoneEnabled
        presentNoticeSubject = dependencies.presentNoticeSubject
        cardPresentPaymentsOnboardingPresenter = dependencies.cardPresentPaymentsOnboardingPresenter
        stores = dependencies.stores
        storage = dependencies.storage
        analytics = dependencies.analytics
        cardPresentPaymentsConfiguration = dependencies.cardPresentPaymentsConfiguration
        title = String(format: Localization.title, formattedTotal)
        showUpsellCardReaderFeatureBanner = cardPresentPaymentsConfiguration.isSupportedCountry

        refreshUpsellCardReaderFeatureBannerVisibility()

        bindStoreCPPState()
        updateCardPaymentVisibility()
    }

    func refreshUpsellCardReaderFeatureBannerVisibility() {
        showUpsellCardReaderFeatureBanner = cardPresentPaymentsConfiguration.isSupportedCountry && upsellCardReadersAnnouncementViewModel.shouldBeVisible
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
                return DDLogError("⛔️ Error updating order: \(error)")
            }

            self.updateOrderAsynchronously()

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
                        useCase: LegacyCollectOrderPaymentProtocol? = nil,
                        onSuccess: @escaping () -> (),
                        onFailure: @escaping () -> ()) {
        switch isTapToPayOnIPhoneEnabled {
        case true:
            newCollectPayment(on: rootViewController, onSuccess: onSuccess, onFailure: onFailure)
        case false:
            legacyCollectPayment(on: rootViewController, useCase: useCase, onSuccess: onSuccess)
        }
    }

    func newCollectPayment(on rootViewController: UIViewController?,
                           useCase: CollectOrderPaymentProtocol? = nil,
                           onSuccess: @escaping () -> (),
                           onFailure: @escaping () -> ()) {
        trackCollectIntention(method: .card)
        OrderDurationRecorder.shared.recordCardPaymentStarted()

        guard let rootViewController = rootViewController else {
            DDLogError("⛔️ Root ViewController is nil, can't present payment alerts.")
            return presentNoticeSubject.send(.error(Localization.genericCollectError))
        }

        // TODO: move onboarding to the CardPresentPaymentPreflightController
        cardPresentPaymentsOnboardingPresenter.showOnboardingIfRequired(
            from: rootViewController) { [weak self] in
                guard let self = self else { return }

                guard let order = self.ordersResultController.fetchedObjects.first else {
                    DDLogError("⛔️ Order not found, can't collect payment.")
                    return self.presentNoticeSubject.send(.error(Localization.genericCollectError))
                }

                let action = CardPresentPaymentAction.selectedPaymentGatewayAccount { paymentGateway in
                    guard let paymentGateway = paymentGateway else {
                        return DDLogError("⛔️ Payment Gateway not found, can't collect payment.")
                    }

                    self.collectPaymentsUseCase = useCase ?? CollectOrderPaymentUseCase(
                        siteID: self.siteID,
                        order: order,
                        formattedAmount: self.formattedTotal,
                        paymentGatewayAccount: paymentGateway,
                        rootViewController: rootViewController,
                        configuration: CardPresentConfigurationLoader().configuration)

                    self.collectPaymentsUseCase?.collectPayment(
                        onFailure: { [weak self] error in
                            self?.trackFlowFailed()
                            // Update order in case its status and/or other details are updated after a failed in-person payment
                            self?.updateOrderAsynchronously()

                            onFailure()
                        },
                        onCancel: {
                            // No tracking required because the flow remains on screen to choose other payment methods.
                        },
                        onCompleted: { [weak self] in
                            // Update order in case its status and/or other details are updated after a successful in-person payment
                            self?.updateOrderAsynchronously()

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

                self.stores.dispatch(action)
            }
    }

    func legacyCollectPayment(on rootViewController: UIViewController?,
                              useCase: LegacyCollectOrderPaymentProtocol? = nil,
                              onSuccess: @escaping () -> ()) {
        trackCollectIntention(method: .card)
        OrderDurationRecorder.shared.recordCardPaymentStarted()

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

                let action = CardPresentPaymentAction.selectedPaymentGatewayAccount { paymentGateway in
                    guard let paymentGateway = paymentGateway else {
                        return DDLogError("⛔️ Payment Gateway not found, can't collect payment.")
                    }

                    self.legacyCollectPaymentsUseCase = useCase ?? LegacyCollectOrderPaymentUseCase(
                        siteID: self.siteID,
                        order: order,
                        formattedAmount: self.formattedTotal,
                        paymentGatewayAccount: paymentGateway,
                        rootViewController: rootViewController,
                        alerts: OrderDetailsPaymentAlerts(transactionType: .collectPayment,
                                                          presentingController: rootViewController),
                        configuration: CardPresentConfigurationLoader().configuration)

                    self.legacyCollectPaymentsUseCase?.collectPayment(
                        onCollect: { [weak self] result in
                            guard result.isFailure else { return }
                            self?.trackFlowFailed()
                        },
                        onCancel: {
                            // No tracking required because the flow remains on screen to choose other payment methods.
                        },
                        onCompleted: { [weak self] in
                            // Update order in case its status and/or other details are updated after a successful in-person payment
                            self?.updateOrderAsynchronously()

                            // Inform success to consumer
                            onSuccess()

                            // Sent notice request
                            self?.presentNoticeSubject.send(.completed)

                            // Make sure we free all the resources
                            self?.legacyCollectPaymentsUseCase = nil

                            // Tracks completion
                            self?.trackFlowCompleted(method: .card)
                        })
                }

                self.stores.dispatch(action)
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

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow() {
        trackFlowCanceled()
    }

    /// Defines if the swipe-to-dismiss gesture on the payment flow should be enabled
    ///
    var shouldEnableSwipeToDismiss: Bool {
        true
    }
}

// MARK: Helpers
private extension PaymentMethodsViewModel {

    /// Observes the store CPP state and update publish variables accordingly.
    ///
    func bindStoreCPPState() {
        ordersResultController.onDidChangeContent = updateCardPaymentVisibility
        try? ordersResultController.performFetch()
    }

    func updateCardPaymentVisibility() {
        guard cardPresentPaymentsConfiguration.isSupportedCountry else {
            showPayWithCardRow = false

            return
        }

        let action = OrderCardPresentPaymentEligibilityAction
            .orderIsEligibleForCardPresentPayment(orderID: orderID,
                                                  siteID: siteID,
                                                  cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration) { [weak self] result in
            switch result {
            case .success(let eligible):
                self?.showPayWithCardRow = eligible
            case .failure(_):
                self?.showPayWithCardRow = false
            }
        }

        stores.dispatch(action)
    }

    func updateOrderAsynchronously() {
        let action = OrderAction.retrieveOrder(siteID: siteID, orderID: orderID) { _, _  in }
        stores.dispatch(action)
    }

    /// Tracks the `paymentsFlowCompleted` event.
    ///
    func trackFlowCompleted(method: WooAnalyticsEvent.PaymentsFlow.PaymentMethod) {
        analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowCompleted(flow: flow, amount: formattedTotal, method: method))
    }

    /// Tracks the `paymentsFlowFailed` event.
    ///
    func trackFlowFailed() {
        analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowFailed(flow: flow, source: .paymentMethod))
    }

    /// Tracks the `paymentsFlowCanceled` event.
    ///
    func trackFlowCanceled() {
        analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowCanceled(flow: flow))
    }

    /// Tracks `paymentsFlowCollect` event.
    ///
    func trackCollectIntention(method: WooAnalyticsEvent.PaymentsFlow.PaymentMethod) {
        analytics.track(event: WooAnalyticsEvent.PaymentsFlow.paymentsFlowCollect(flow: flow, method: method))
    }
}

private extension PaymentMethodsViewModel {
    enum Localization {
        static let markAsPaidError = NSLocalizedString("There was an error while marking the order as paid.",
                                                       comment: "Text when there is an error while marking the order as paid for during payment.")

        static let genericCollectError = NSLocalizedString("There was an error while trying to collect the payment.",
                                                       comment: "Text when there is an unknown error while trying to collect payments")

        static let title = NSLocalizedString("Take Payment (%1$@)",
                                             comment: "Navigation bar title for the Payment Methods screens. " +
                                             "%1$@ is a placeholder for the total amount to collect")

        static func markAsPaidInfo(total: String) -> String {
            NSLocalizedString("This will mark your order as complete if you received \(total) outside of WooCommerce",
                              comment: "Alert info when selecting the cash payment method during payments")
        }
    }
}
