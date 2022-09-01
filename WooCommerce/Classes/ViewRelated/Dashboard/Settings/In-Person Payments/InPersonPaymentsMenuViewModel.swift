import Foundation
import Yosemite

class InPersonPaymentsMenuViewModel: ObservableObject {

    // MARK: - Dependencies
    struct Dependencies {
        let stores: StoresManager
        let noticePresenter: NoticePresenter
        let analytics: Analytics

        init(stores: StoresManager = ServiceLocator.stores,
             noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
             analytics: Analytics = ServiceLocator.analytics) {
            self.stores = stores
            self.noticePresenter = noticePresenter
            self.analytics = analytics
        }
    }

    private let dependencies: Dependencies

    private var stores: StoresManager {
        dependencies.stores
    }

    private var noticePresenter: NoticePresenter {
        dependencies.noticePresenter
    }

    private var analytics: Analytics {
        dependencies.analytics
    }

    // MARK: - Output properties
    @Published var cashOnDeliveryEnabledState: Bool = false

    // MARK: - Configuration properties
    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    private let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    private let paymentGatewaysFetchedResultsController: ResultsController<StoragePaymentGateway>?

    var selectedPlugin: CardPresentPaymentsPlugin?

    init(dependencies: Dependencies = Dependencies(),
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration) {
        self.dependencies = dependencies
        self.cardPresentPaymentsConfiguration = configuration
        paymentGatewaysFetchedResultsController = Self.createPaymentGatewaysResultsController(
            siteID: dependencies.stores.sessionManager.defaultStoreID)
        observePaymentGateways()
    }

    // MARK: - PaymentGateway observation
    private func observePaymentGateways() {
        paymentGatewaysFetchedResultsController?.onDidChangeContent = updateCashOnDeliveryEnabledState
        paymentGatewaysFetchedResultsController?.onDidResetContent = updateCashOnDeliveryEnabledState
        do {
            try paymentGatewaysFetchedResultsController?.performFetch()
            updateCashOnDeliveryEnabledState()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    private static func createPaymentGatewaysResultsController(siteID: Int64?) -> ResultsController<StoragePaymentGateway>? {
        guard let siteID = siteID else {
            return nil
        }

        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController<StoragePaymentGateway>(storageManager: ServiceLocator.storageManager,
                                                        matching: predicate,
                                                        sortedBy: [])
    }

    private func updateCashOnDeliveryEnabledState() {
        cashOnDeliveryEnabledState = cashOnDeliveryGateway?.enabled ?? false
    }

    private var cashOnDeliveryGateway: PaymentGateway? {
        paymentGatewaysFetchedResultsController?.fetchedObjects.first(where: {
            $0.gatewayID == PaymentGateway.Constants.cashOnDeliveryGatewayID
        })
    }

    // MARK: - Toggle Cash on Delivery Payment Gateway

    func updateCashOnDeliverySetting(enabled: Bool) {
        switch enabled {
        case true:
            enableCashOnDeliveryGateway()
        case false:
            disableCashOnDeliveryGateway()
        }
    }

    private func enableCashOnDeliveryGateway() {
        guard let siteID = siteID else {
            return
        }

        let action = PaymentGatewayAction.updatePaymentGateway(PaymentGateway.defaultPayInPersonGateway(siteID: siteID)) { [weak self] result in
            guard let self = self else { return }
            guard result.isSuccess else {
                DDLogError("💰 Could not update Payment Gateway: \(String(describing: result.failure))")
                // Resetting the toggle to the most recent stored value, or false because we failed to make it true.
                self.cashOnDeliveryEnabledState = self.cashOnDeliveryGateway?.enabled ?? false
                self.displayEnableCashOnDeliveryFailureNotice()
                self.trackEnableCashOnDeliveryFailed(error: result.failure)
                return
            }

            self.trackEnableCashOnDeliverySuccess()
        }
        stores.dispatch(action)
    }

    private func displayEnableCashOnDeliveryFailureNotice() {
        let notice = Notice(title: Localization.enableCashOnDeliveryFailureNoticeTitle,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: Localization.cashOnDeliveryFailureNoticeRetryTitle,
                            actionHandler: enableCashOnDeliveryGateway)

        noticePresenter.enqueue(notice: notice)
    }

    private func disableCashOnDeliveryGateway() {
        guard let cashOnDeliveryGateway = cashOnDeliveryGateway else {
            return
        }

        let disabledPaymentGateway = cashOnDeliveryGateway.copy(enabled: false)
        let action = PaymentGatewayAction.updatePaymentGateway(disabledPaymentGateway) { [weak self] result in
            guard let self = self else { return }
            guard result.isSuccess else {
                DDLogError("💰 Could not update Payment Gateway: \(String(describing: result.failure))")
                // Resetting the toggle to the most recent stored value, or true because we failed to make it false.
                self.cashOnDeliveryEnabledState = self.cashOnDeliveryGateway?.enabled ?? true
                self.displayDisableCashOnDeliveryFailureNotice()
                return
            }

        }
        stores.dispatch(action)
    }

    private func displayDisableCashOnDeliveryFailureNotice() {
        let notice = Notice(title: Localization.disableCashOnDeliveryFailureNoticeTitle,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: Localization.cashOnDeliveryFailureNoticeRetryTitle,
                            actionHandler: disableCashOnDeliveryGateway)

        noticePresenter.enqueue(notice: notice)
    }

    // MARK: - Learn More

    private var learnMoreURL: URL {
        (selectedPlugin ?? .wcPay).cashOnDeliveryLearnMoreURL
    }

    func learnMoreTapped(from viewController: UIViewController) {
        WebviewHelper.launch(learnMoreURL, with: viewController)
    }
}

// MARK: - Analytics
extension InPersonPaymentsMenuViewModel {
    private typealias Event = WooAnalyticsEvent.InPersonPayments

    private func trackEnableCashOnDeliverySuccess() {
        let event = Event.enableCashOnDeliverySuccess(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                      source: .paymentsHub)
        analytics.track(event: event)
    }

    private func trackEnableCashOnDeliveryFailed(error: Error?) {
        let event = Event.enableCashOnDeliveryFailed(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                     error: error,
                                                     source: .paymentsHub)
        analytics.track(event: event)
    }
}

private enum Localization {
    static let enableCashOnDeliveryFailureNoticeTitle = NSLocalizedString(
        "Failed to enable Pay in Person. Please try again later.",
        comment: "Error displayed when the attempt to enable a Pay in Person checkout payment option fails")

    static let disableCashOnDeliveryFailureNoticeTitle = NSLocalizedString(
        "Failed to disable Pay in Person. Please try again later.",
        comment: "Error displayed when the attempt to disable a Pay in Person checkout payment option fails")

    static let cashOnDeliveryFailureNoticeRetryTitle = NSLocalizedString(
        "Retry",
        comment: "Retry Action on error displayed when the attempt to toggle a Pay in Person checkout payment option fails")
}
