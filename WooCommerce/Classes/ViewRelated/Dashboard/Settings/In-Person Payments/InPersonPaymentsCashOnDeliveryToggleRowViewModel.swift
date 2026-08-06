import Foundation
import UIKit
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

protocol InPersonPaymentsCashOnDeliveryToggleRowViewModelProtocol {
    func refreshState()
    var selectedPlugin: CardPresentPaymentsPlugin? { get set }
}

final class InPersonPaymentsCashOnDeliveryToggleRowViewModel: ObservableObject, InPersonPaymentsCashOnDeliveryToggleRowViewModelProtocol {

    // MARK: - Dependencies
    struct Dependencies {
        let stores: StoresManager
        let storageManager: StorageManagerType
        let noticePresenter: NoticePresenter
        let analytics: Analytics

        init(stores: StoresManager = ServiceLocator.stores,
             storageManager: StorageManagerType = ServiceLocator.storageManager,
             noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
             analytics: Analytics = ServiceLocator.analytics) {
            self.stores = stores
            self.storageManager = storageManager
            self.noticePresenter = noticePresenter
            self.analytics = analytics
        }
    }

    private let dependencies: Dependencies

    private var stores: StoresManager {
        dependencies.stores
    }

    private var storageManager: StorageManagerType {
        dependencies.storageManager
    }

    private var noticePresenter: NoticePresenter {
        dependencies.noticePresenter
    }

    private var analytics: Analytics {
        dependencies.analytics
    }

    // MARK: - Output properties
    @Published var cashOnDeliveryEnabledState: Bool = false

    /// Confirmation the user must accept before the toggle change is applied. Non-nil while the alert is shown.
    @Published var pendingToggleConfirmation: ToggleConfirmation?

    struct ToggleConfirmation: Equatable {
        let title: String
        let message: String
        let confirmButtonTitle: String
        let cancelButtonTitle: String
        let targetState: Bool
    }

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
            siteID: dependencies.stores.sessionManager.defaultStoreID,
            storageManager: dependencies.storageManager)
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

    private static func createPaymentGatewaysResultsController(siteID: Int64?,
                                                               storageManager: StorageManagerType) -> ResultsController<StoragePaymentGateway>? {
        guard let siteID else {
            return nil
        }

        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController<StoragePaymentGateway>(storageManager: storageManager,
                                                        matching: predicate,
                                                        sortedBy: [])
    }

    func refreshState() {
        guard let siteID else {
            return
        }

        let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: siteID) { _ in }
        stores.dispatch(action)
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

    /// Called when the user flips the toggle. Asks for confirmation instead of applying the change directly.
    func cashOnDeliveryToggleRequested(enabled: Bool) {
        pendingToggleConfirmation = makeToggleConfirmation(enabled: enabled)
    }

    /// Called when the user confirms the pending toggle change from the confirmation alert.
    func confirmCashOnDeliveryToggle(targetState: Bool) {
        pendingToggleConfirmation = nil
        // Optimistically reflects the new state while the update is in flight; failure handlers revert it.
        cashOnDeliveryEnabledState = targetState
        updateCashOnDeliverySetting(enabled: targetState)
    }

    /// Called when the confirmation alert is dismissed without confirming. The gateway is left untouched.
    func dismissCashOnDeliveryToggleConfirmation() {
        pendingToggleConfirmation = nil
    }

    private func makeToggleConfirmation(enabled: Bool) -> ToggleConfirmation {
        guard enabled else {
            return ToggleConfirmation(title: Localization.disableConfirmationTitle,
                                      message: Localization.disableConfirmationMessage,
                                      confirmButtonTitle: Localization.disableConfirmationButton,
                                      cancelButtonTitle: Localization.confirmationCancelButton,
                                      targetState: false)
        }
        return ToggleConfirmation(title: Localization.enableConfirmationTitle,
                                  message: enableConfirmationMessage,
                                  confirmButtonTitle: Localization.enableConfirmationButton,
                                  cancelButtonTitle: Localization.confirmationCancelButton,
                                  targetState: true)
    }

    /// Enabling overwrites the gateway's customer-facing title with "Pay in Person", so the message warns
    /// about the rename when the store currently uses a different title.
    private var enableConfirmationMessage: String {
        guard let currentTitle = cashOnDeliveryGateway?.title,
              currentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              currentTitle.caseInsensitiveCompare(PaymentGateway.defaultPayInPersonTitle) != .orderedSame else {
            return Localization.enableConfirmationMessage
        }
        return String.localizedStringWithFormat(Localization.enableConfirmationMessageRenameFormat, currentTitle)
    }

    func updateCashOnDeliverySetting(enabled: Bool) {
        trackCashOnDeliveryToggled(enabled: enabled)
        switch enabled {
        case true:
            enableCashOnDeliveryGateway()
        case false:
            disableCashOnDeliveryGateway()
        }
    }

    private func enableCashOnDeliveryGateway() {
        guard let siteID else {
            return
        }

        let action = PaymentGatewayAction.updatePaymentGateway(PaymentGateway.defaultPayInPersonGateway(siteID: siteID)) { [weak self] result in
            guard let self else { return }
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
        guard let cashOnDeliveryGateway else {
            return
        }

        let disabledPaymentGateway = cashOnDeliveryGateway.copy(enabled: false)
        let action = PaymentGatewayAction.updatePaymentGateway(disabledPaymentGateway) { [weak self] result in
            guard let self else { return }
            guard result.isSuccess else {
                DDLogError("💰 Could not update Payment Gateway: \(String(describing: result.failure))")
                // Resetting the toggle to the most recent stored value, or true because we failed to make it false.
                self.cashOnDeliveryEnabledState = self.cashOnDeliveryGateway?.enabled ?? true
                self.displayDisableCashOnDeliveryFailureNotice()
                self.trackDisableCashOnDeliveryFailed(error: result.failure)
                return
            }

            self.trackDisableCashOnDeliverySuccess()
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
        analytics.track(.paymentsHubCashOnDeliveryToggleLearnMoreTapped)
    }

    var learnMoreViewModel: LearnMoreViewModel {
        LearnMoreViewModel(
            url: learnMoreURL,
            linkText: Localization.toggleEnableCashOnDeliveryLearnMoreLink,
            formatText: Localization.toggleEnableCashOnDeliveryLearnMoreFormat,
            tappedAnalyticEvent: learnMoreTappedEvent)
    }
}

// MARK: - Analytics
private extension InPersonPaymentsCashOnDeliveryToggleRowViewModel {
    typealias Event = WooAnalyticsEvent.InPersonPayments

    func trackCashOnDeliveryToggled(enabled: Bool) {
        let event = Event.paymentsHubCashOnDeliveryToggled(enabled: enabled,
                                                           countryCode: cardPresentPaymentsConfiguration.countryCode)
        analytics.track(event: event)
    }

    func trackEnableCashOnDeliverySuccess() {
        let event = Event.enableCashOnDeliverySuccess(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                      source: .paymentsHub)
        analytics.track(event: event)
    }

    func trackEnableCashOnDeliveryFailed(error: Error?) {
        let event = Event.enableCashOnDeliveryFailed(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                     error: error,
                                                     source: .paymentsHub)
        analytics.track(event: event)
    }

    func trackDisableCashOnDeliverySuccess() {
        let event = Event.disableCashOnDeliverySuccess(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                       source: .paymentsHub)
        analytics.track(event: event)
    }

    func trackDisableCashOnDeliveryFailed(error: Error?) {
        let event = Event.disableCashOnDeliveryFailed(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                      error: error,
                                                      source: .paymentsHub)
        analytics.track(event: event)
    }

    var learnMoreTappedEvent: WooAnalyticsEvent {
        Event.cashOnDeliveryToggleLearnMoreTapped(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                  source: .paymentsHub)
    }
}

private enum Localization {
    static let enableConfirmationTitle = NSLocalizedString(
        "menu.payments.payInPerson.toggle.enableConfirmation.title",
        value: "Enable Pay In Person?",
        comment: "Title of the confirmation alert shown when the merchant turns on the Pay In Person checkout " +
        "payment option in the Payments menu")

    static let enableConfirmationMessage = NSLocalizedString(
        "menu.payments.payInPerson.toggle.enableConfirmation.message",
        value: "This enables the Cash on Delivery payment method at your store’s checkout.",
        comment: "Message of the confirmation alert shown when the merchant turns on the Pay In Person checkout " +
        "payment option and the payment method already has the default Pay in Person title")

    static let enableConfirmationMessageRenameFormat = NSLocalizedString(
        "menu.payments.payInPerson.toggle.enableConfirmation.messageRename",
        value: "This enables the Cash on Delivery payment method at your store’s checkout and renames it " +
        "from “%1$@” to “Pay in Person” for your customers, including on your website’s checkout.",
        comment: "Message of the confirmation alert shown when the merchant turns on the Pay In Person checkout " +
        "payment option and the payment method has a custom title which will be replaced. " +
        "%1$@ is a placeholder for the payment method's current customer-facing title, e.g. \"Cash on delivery\".")

    static let enableConfirmationButton = NSLocalizedString(
        "menu.payments.payInPerson.toggle.enableConfirmation.confirmButton",
        value: "Enable",
        comment: "Confirmation button of the alert shown when the merchant turns on the Pay In Person checkout " +
        "payment option in the Payments menu")

    static let disableConfirmationTitle = NSLocalizedString(
        "menu.payments.payInPerson.toggle.disableConfirmation.title",
        value: "Disable Pay In Person?",
        comment: "Title of the confirmation alert shown when the merchant turns off the Pay In Person checkout " +
        "payment option in the Payments menu")

    static let disableConfirmationMessage = NSLocalizedString(
        "menu.payments.payInPerson.toggle.disableConfirmation.message",
        value: "This disables the Cash on Delivery payment method at your store’s checkout, " +
        "so customers won’t be able to select it.",
        comment: "Message of the confirmation alert shown when the merchant turns off the Pay In Person checkout " +
        "payment option in the Payments menu")

    static let disableConfirmationButton = NSLocalizedString(
        "menu.payments.payInPerson.toggle.disableConfirmation.confirmButton",
        value: "Disable",
        comment: "Confirmation button of the alert shown when the merchant turns off the Pay In Person checkout " +
        "payment option in the Payments menu")

    static let confirmationCancelButton = NSLocalizedString(
        "menu.payments.payInPerson.toggle.confirmation.cancelButton",
        value: "Cancel",
        comment: "Cancel button of the confirmation alert shown when the merchant toggles the Pay In Person " +
        "checkout payment option in the Payments menu. Tapping it leaves the payment method unchanged.")

    static let enableCashOnDeliveryFailureNoticeTitle = NSLocalizedString(
        "menu.payments.payInPerson.toggle.enableFailureNotice.title",
        value: "Failed to enable Pay In Person. Please try again later.",
        comment: "Error displayed when the attempt to enable a Pay In Person checkout payment option fails")

    static let disableCashOnDeliveryFailureNoticeTitle = NSLocalizedString(
        "menu.payments.payInPerson.toggle.disableFailureNotice.title",
        value: "Failed to disable Pay In Person. Please try again later.",
        comment: "Error displayed when the attempt to disable a Pay In Person checkout payment option fails")

    static let cashOnDeliveryFailureNoticeRetryTitle = NSLocalizedString(
        "Retry",
        comment: "Retry Action on error displayed when the attempt to toggle a Pay in Person checkout payment option fails")

    static let toggleEnableCashOnDeliveryLearnMoreFormat = NSLocalizedString(
        "menu.payments.payInPerson.learnMore.description.payInPersonCasing",
        value: "The Pay In Person checkout option lets you accept payments for website orders, on collection or delivery. %1$@",
        comment: "A label prompting users to learn more about adding Pay In Person to their checkout. " +
        "%1$@ is a placeholder that always replaced with \"Learn more\" string, " +
        "which should be translated separately and considered part of this sentence.")

    static let toggleEnableCashOnDeliveryLearnMoreLink = NSLocalizedString(
        "menu.payments.payInPerson.learnMore.link",
        value: "Learn more",
        comment: "The \"Learn more\" string replaces the placeholder in a label prompting users to learn " +
        "more about adding Pay in Person to their checkout. ")
}
