import Foundation
import Yosemite
import protocol WooFoundation.Analytics

struct InPersonPaymentsOnboardingErrorButtonViewModel {
    let text: String
    let isExternalLink: Bool

    private let analyticReason: String

    private let cardPresentConfiguration: CardPresentPaymentsConfiguration

    let action: () -> Void

    init(text: String,
         analyticReason: String,
         cardPresentConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         plugin: CardPresentPaymentsPlugin?,
         isExternalLink: Bool = false,
         trackTap: Bool = true,
         analytics: Analytics = ServiceLocator.analytics,
         action: @escaping () -> Void) {
        self.text = text
        self.isExternalLink = isExternalLink
        self.analyticReason = analyticReason
        self.cardPresentConfiguration = cardPresentConfiguration
        self.action = {
            if trackTap {
                analytics.track(
                    event: .InPersonPayments.cardPresentOnboardingCtaTapped(
                        reason: analyticReason,
                        countryCode: cardPresentConfiguration.countryCode,
                        gatewayID: plugin?.gatewayID
                    ))
            }
            action()
        }
    }
}
