import Foundation
import SwiftUI
import Yosemite
import WooFoundation

struct TapToPayAwarenessMomentView: View {
    @Environment(\.dismiss) private var dismiss
    private let imageName: String

    private let deepLinkNavigator: DeepLinkNavigator?
    @State private var destination: (any DeepLinkDestinationProtocol)?

    init(deepLinkNavigator: DeepLinkNavigator? = AppDelegate.shared.tabBarController,
         countryCode: CountryCode = CardPresentConfigurationLoader().configuration.countryCode) {
        self.deepLinkNavigator = deepLinkNavigator
        switch countryCode {
        case .GB:
            imageName = "tap-to-pay-education-intro-gb"
        default:
            imageName = "tap-to-pay-education-intro-us"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Constants.spacing) {
                orientationAdaptiveStack(spacing: Constants.spacing) {
                    VStack(spacing: Constants.spacing) {
                        Text(Localization.title)
                            .font(.title.weight(.bold))
                            .multilineTextAlignment(.center)
                        Text(Localization.subtitle)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                }

                Spacer()

                Button(Localization.enable, action: {
                    destination = PaymentsMenuDestination.tapToPay
                    dismiss()

                })
                .buttonStyle(PrimaryButtonStyle())

                Button(Localization.learnMore, action: {
                    destination = PaymentsMenuDestination.aboutTapToPay
                    dismiss()

                })
                .buttonStyle(TextButtonStyle())
                .padding(.bottom)
            }
            .padding([.horizontal])
            .wooNavigationBarStyle()
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Localization.close, action: {
                        dismiss()
                    })
                }
            }
            .onDisappear {
                if let destination {
                    deepLinkNavigator?.navigate(to: destination)
                }
            }
        }
    }

    private func orientationAdaptiveStack(spacing: CGFloat,
                                          @ViewBuilder content: @escaping () -> some View) -> some View {
        Group {
            if UIDevice.current.orientation.isPortrait {
                VStack(spacing: spacing, content: content)
            } else {
                HStack(spacing: spacing, content: content)
            }
        }
    }
}

private enum Constants {
    static let spacing: CGFloat = 20
}

private enum Localization {
    static let close = NSLocalizedString(
        "tapToPay.awarenessMoment.closeButton",
        value: "Close",
        comment: "Title of the button to dismiss the Tap to Pay awareness screen"
    )

    static let title = NSLocalizedString(
        "tapToPay.awarenessMoment.title",
        value: "Tap to Pay on iPhone. Now available.",
        comment: "Title for the Tap to Pay modal promoting the feature. When using the name “Tap to Pay " +
        "on iPhone” in headlines or copy, do not shorten to “Tap to Pay” or “Apple Tap to Pay. Always " +
        "typeset “Tap to Pay on iPhone” as five words. The T and Ps should be uppercased, followed by " +
        "lowercase letters."
    )

    static let subtitle = NSLocalizedString(
        "tapToPay.awarenessMoment.subtitle",
        value: "Accept contactless payments with only an iPhone.",
        comment: "A subtitle for the Tap to Pay modal promoting the feature."
    )

    static let enable = NSLocalizedString(
        "tapToPay.awarenessMoment.enableButton",
        value: "Enable now",
        comment: "A title for CTA to start Tap to Pay set up process"
    )

    static let learnMore = NSLocalizedString(
        "tapToPay.awarenessMoment.learnMore",
        value: "Learn more",
        comment: "A title for CTA to open a view explaining Tap to Pay"
    )
}
