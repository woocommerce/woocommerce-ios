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

        let action = PaymentGatewayAction.updatePaymentGateway(PaymentGateway.defaultPayInPersonGateway(siteID: siteID)) { [weak self] result in
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
extension InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel {
    private typealias Event = WooAnalyticsEvent.InPersonPayments

    var learnMoreEvent: WooAnalyticsEvent {
        Event.cardPresentOnboardingLearnMoreTapped(reason: analyticReason,
                                                   countryCode: cardPresentPaymentsConfiguration.countryCode)
    }

    private func trackSkipTapped() {
        let event = Event.cardPresentOnboardingStepSkipped(reason: analyticReason,
                                                           remindLater: false,
                                                           countryCode: cardPresentPaymentsConfiguration.countryCode)
        analytics.track(event: event)
    }

    private func trackEnableTapped() {
        let event = Event.cardPresentOnboardingCtaTapped(reason: analyticReason,
                                                         countryCode: cardPresentPaymentsConfiguration.countryCode)
        analytics.track(event: event)
    }

    private func trackEnableCashOnDeliverySuccess() {
        let event = Event.enableCashOnDeliverySuccess(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                      source: .onboarding)
        analytics.track(event: event)
    }

    private func trackEnableCashOnDeliveryFailed(error: Error?) {
        let event = Event.enableCashOnDeliveryFailed(countryCode: cardPresentPaymentsConfiguration.countryCode,
                                                     error: error,
                                                     source: .onboarding)
        analytics.track(event: event)
    }
}

private enum Localization {
    static let cashOnDeliveryFailureNoticeTitle = NSLocalizedString(
        "Failed to enable Pay in Person. Please try again later.",
        comment: "Error displayed when the attempt to enable a Pay in Person checkout payment option fails")

    static let cashOnDeliveryFailureNoticeRetryTitle = NSLocalizedString(
        "Retry",
        comment: "Retry Action on error displayed when the attempt to enable a Pay in Person checkout payment option fails")
}
