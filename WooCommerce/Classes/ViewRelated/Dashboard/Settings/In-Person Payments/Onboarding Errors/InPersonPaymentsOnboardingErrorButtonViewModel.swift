import Foundation
import Yosemite

struct InPersonPaymentsOnboardingErrorButtonViewModel {
    let text: String

    private let analyticReason: String

    private let cardPresentConfiguration: CardPresentPaymentsConfiguration

    let action: () -> Void

    init(text: String,
         analyticReason: String,
         cardPresentConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         plugin: CardPresentPaymentsPlugin?,
         action: @escaping () -> Void) {
        self.text = text
        self.analyticReason = analyticReason
        self.cardPresentConfiguration = cardPresentConfiguration
        self.action = {
            ServiceLocator.analytics.track(
                event: .InPersonPayments.cardPresentOnboardingCtaTapped(
                    reason: analyticReason,
                    countryCode: cardPresentConfiguration.countryCode,
                    gatewayID: plugin?.gatewayID
                ))
            action()
        }
    }
}
