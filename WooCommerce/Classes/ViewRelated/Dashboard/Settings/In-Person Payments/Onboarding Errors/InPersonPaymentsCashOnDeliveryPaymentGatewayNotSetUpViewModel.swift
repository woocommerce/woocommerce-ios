import Foundation
import Yosemite

final class InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel: ObservableObject {
    let completion: () -> Void
    private let stores: StoresManager
    private let noticePresenter: NoticePresenter
    private let analytics: Analytics
    private let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    @Published var awaitingResponse = false

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    init(stores: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         analytics: Analytics = ServiceLocator.analytics,
         configuration: CardPresentPaymentsConfiguration,
         completion: @escaping () -> Void) {
        self.stores = stores
        self.noticePresenter = noticePresenter
        self.analytics = analytics
        self.cardPresentPaymentsConfiguration = configuration
        self.completion = completion
    }

    func skipTapped() {
        trackSkipTapped()

        guard let siteID = siteID else {
            return completion()
        }

        let action = AppSettingsAction.setSkippedCashOnDeliveryOnboardingStep(siteID: siteID)
        stores.dispatch(action)
        completion()
    }

    func enableTapped() {
        guard let siteID = siteID else {
            return completion()
        }

        awaitingResponse = true

        let action = PaymentGatewayAction.updatePaymentGateway(defaultCashOnDeliveryGateway(siteID: siteID)) { [weak self] result in
            guard let self = self else { return }
            guard result.isSuccess else {
                DDLogError("💰 Could not update Payment Gateway: \(String(describing: result.failure))")
                self.awaitingResponse = false
                self.displayEnableCashOnDeliveryFailureNotice()
                return
            }

            self.completion()
        }
        stores.dispatch(action)
    }

    private func defaultCashOnDeliveryGateway(siteID: Int64) -> PaymentGateway {
        PaymentGateway(siteID: siteID,
                       gatewayID: Constants.cashOnDeliveryGatewayID,
                       title: Localization.cashOnDeliveryCheckoutTitle,
                       description: Localization.cashOnDeliveryCheckoutDescription,
                       enabled: true,
                       features: [.products],
                       instructions: Localization.cashOnDeliveryCheckoutInstructions)
    }

    private func displayEnableCashOnDeliveryFailureNotice() {
        let notice = Notice(title: Localization.cashOnDeliveryFailureNoticeTitle,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: Localization.cashOnDeliveryFailureNoticeRetryTitle,
                            actionHandler: enableTapped)

        noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Analytics
private extension InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel {
    private typealias Event = WooAnalyticsEvent.InPersonPayments

    private var reason: String {
        CardPresentPaymentOnboardingState.codPaymentGatewayNotSetUp.reasonForAnalytics ?? ""
    }

    private func trackSkipTapped() {
        let event = Event.cardPresentOnboardingStepSkipped(reason: reason,
                                                           remindLater: false,
                                                           countryCode: cardPresentPaymentsConfiguration.countryCode)
        analytics.track(event: event)
    }
}

private enum Localization {
    static let cashOnDeliveryCheckoutTitle = NSLocalizedString(
        "Pay in Person",
        comment: "Customer-facing title for the payment option added to the store checkout when the merchant enables " +
        "Pay in Person")

    static let cashOnDeliveryCheckoutDescription = NSLocalizedString(
        "Pay by card or another accepted payment method",
        comment: "Customer-facing description showing more details about the Pay in Person option which is added to " +
        "the store checkout when the merchant enables Pay in Person")

    static let cashOnDeliveryCheckoutInstructions = NSLocalizedString(
        "Pay by card or another accepted payment method",
        comment: "Customer-facing instructions shown on Order Thank-you pages and confirmation emails, showing more " +
        "details about the Pay in Person option added to the store checkout when the merchant enables Pay in Person")

    static let cashOnDeliveryFailureNoticeTitle = NSLocalizedString(
        "Failed to enable Pay in Person. Please try again later.",
        comment: "Error displayed when the attempt to enable a Pay in Person checkout payment option fails")

    static let cashOnDeliveryFailureNoticeRetryTitle = NSLocalizedString(
        "Retry",
        comment: "Retry Action on error displayed when the attempt to enable a Pay in Person checkout payment option fails")
}

private enum Constants {
    static let cashOnDeliveryGatewayID = "cod"
}
