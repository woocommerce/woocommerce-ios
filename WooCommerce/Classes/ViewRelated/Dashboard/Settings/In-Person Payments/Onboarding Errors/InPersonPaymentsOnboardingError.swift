import SwiftUI
import Yosemite
import struct WooFoundation.ScrollableVStack

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
        ScrollableVStack(padding: 0) {
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

                if let buttonViewModel {
                    Button(action: buttonViewModel.action) {
                        buttonLabel(for: buttonViewModel)
                    }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.bottom, secondaryButtonViewModel == nil ? 24.0 : 0)
                }
                if let secondaryButtonViewModel {
                    Button(action: secondaryButtonViewModel.action) {
                        buttonLabel(for: secondaryButtonViewModel)
                    }
                        .buttonStyle(SecondaryButtonStyle())
                }
                if learnMore {
                    InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel(paymentGateway: plugin ?? .wcPay,
                                                                            tappedAnalyticEvent: learnMoreAnalyticEvent))
                    .padding(.vertical, 8)
                }
            }.padding()
        }
    }

    private func buttonLabel(for viewModel: InPersonPaymentsOnboardingErrorButtonViewModel) -> some View {
        HStack {
            Text(viewModel.text)
            if viewModel.isExternalLink {
                Image(uiImage: .externalImage).accessibilityHidden(true)
            }
        }
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
