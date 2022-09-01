import Foundation
import Yosemite

final class InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel: ObservableObject {
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
    let completion: () -> Void

    @Published var awaitingResponse = false

    let analyticReason: String

    // MARK: - Configuration properties
    private let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    private var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    let learnMoreURL: URL

    init(dependencies: Dependencies = Dependencies(),
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         plugin: CardPresentPaymentsPlugin,
         analyticReason: String,
         completion: @escaping () -> Void) {
        self.dependencies = dependencies
        self.cardPresentPaymentsConfiguration = configuration
        self.learnMoreURL = plugin.cashOnDeliveryLearnMoreURL
        self.analyticReason = analyticReason
        self.completion = completion
    }

    // MARK: - Actions
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
        trackEnableTapped()

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
                self.trackEnableCashOnDeliveryFailed(error: result.failure)
                return
            }

            self.trackEnableCashOnDeliverySuccess()
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
    typealias Event = WooAnalyticsEvent.InPersonPayments

    func trackSkipTapped() {
        let event = Event.cardPresentOnboardingStepSkipped(reason: analyticReason,
                                                           remindLater: false,
                                                           countryCode: cardPresentPaymentsConfiguration.countryCode)
        analytics.track(event: event)
    }

    func trackEnableTapped() {
        let event = Event.cardPresentOnboardingCtaTapped(reason: analyticReason,
                                                         countryCode: cardPresentPaymentsConfiguration.countryCode)
        analytics.track(event: event)
    }

    func trackEnableCashOnDeliverySuccess() {
        let event = Event.enableCashOnDeliverySuccess(countryCode: cardPresentPaymentsConfiguration.countryCode)
        analytics.track(event: event)
    }

    func trackEnableCashOnDeliveryFailed(error: Error?) {
        let event = Event.enableCashOnDeliveryFailed(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                     error: error)
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

private extension CardPresentPaymentsPlugin {
    var cashOnDeliveryLearnMoreURL: URL {
        switch self {
        case .wcPay:
            return WooConstants.URLs.wcPayCashOnDeliveryLearnMoreUrl.asURL()
        case .stripe:
            return WooConstants.URLs.stripeCashOnDeliveryLearnMoreUrl.asURL()
        }
    }
}
