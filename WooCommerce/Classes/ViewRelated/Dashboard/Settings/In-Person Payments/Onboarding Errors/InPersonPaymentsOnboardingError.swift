import SwiftUI
import Yosemite

struct InPersonPaymentsOnboardingError: View {
    let title: String
    let message: String
    let image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo
    let supportLink: Bool
    let learnMore: Bool
    let analyticReason: String
    var buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel? = nil

    var body: some View {
        VStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: title,
                message: message,
                image: image,
                supportLink: supportLink
            )

            Spacer()

            if let buttonViewModel = buttonViewModel {
                Button(buttonViewModel.text, action: buttonViewModel.action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.bottom, 24.0)
            }
            if learnMore {
                InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel(tappedAnalyticEvent: learnMoreAnalyticEvent))
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
                                                                                countryCode: CardPresentConfigurationLoader().configuration.countryCode)
    }
}
