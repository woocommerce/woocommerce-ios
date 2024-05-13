import SwiftUI
import Yosemite

struct InPersonPaymentsOnboardingError: View {
    let title: String
    let message: String
    let image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo
    let supportLink: Bool
    let learnMore: Bool
    let analyticReason: String
    let plugin: CardPresentPaymentsPlugin?
    var buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel? = nil
    var secondaryButtonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel? = nil

    var body: some View {
        VStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: title,
                message: message,
                secondaryMessage: nil,
                image: image,
                supportLink: supportLink
            )

            Spacer()

            if let buttonViewModel = buttonViewModel {
                Button(buttonViewModel.text, action: buttonViewModel.action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.bottom, secondaryButtonViewModel == nil ? 24.0 : 0)
            }
            if let secondaryButtonViewModel = secondaryButtonViewModel {
                Button(secondaryButtonViewModel.text, action: secondaryButtonViewModel.action)
                    .buttonStyle(SecondaryButtonStyle())
            }
            if learnMore {
                InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel(tappedAnalyticEvent: learnMoreAnalyticEvent))
                    .padding(.vertical, 8)
            }
        }.padding()
    }
}

extension CardPresentPaymentsPlugin {
    public var image: UIImage {
        switch self {
        case .wcPay:
            return .wcPayPlugin
        case .stripe:
            return .stripePlugin
        }
    }
}

private extension InPersonPaymentsOnboardingError {
    var learnMoreAnalyticEvent: WooAnalyticsEvent? {
        WooAnalyticsEvent.InPersonPayments.cardPresentOnboardingLearnMoreTapped(reason: analyticReason,
                                                                                countryCode: CardPresentConfigurationLoader().configuration.countryCode,
                                                                                gatewayID: plugin?.gatewayID)
    }
}
