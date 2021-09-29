import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) var customOpenURL

    var body: some View {
        Link(destination: Constants.learnMoreURL!) {
            Label {
                Text(Localization.learnMore)
                    .font(.subheadline)
                    .foregroundColor(Color(.accent))
            } icon: {
                Image(uiImage: .infoOutlineImage)
                    .resizable()
                    .foregroundColor(Color(.textSubtle))
                    .frame(width: iconSize, height: iconSize)
            }.labelStyle(VerticallyCenteredLabelStyle())
        }.onOpenURL(perform: { url in
            ServiceLocator.analytics.track(.cardPresentOnboardingLearnMoreTapped)
            customOpenURL?(url)
        })
    }

    var iconSize: CGFloat {
        UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 20)
    }

    struct VerticallyCenteredLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center, spacing: 20) {
                configuration.icon
                configuration.title
            }
        }
    }
}

private enum Constants {
    static let learnMoreURL = URL(string: "https://woocommerce.com/payments")
}

private enum Localization {
    static let unavailable = NSLocalizedString(
        "In-Person Payments is currently unavailable",
        comment: "Title for the error screen when In-Person Payments is unavailable"
    )

    static let acceptCash = NSLocalizedString(
        "You can still accept in-person cash payments by enabling the “Cash on Delivery” payment method on your store.",
        comment: "Generic error message when In-Person Payments is unavailable"
    )

    static let learnMore = NSLocalizedString(
        "Tap to learn more about accepting payments with your mobile device and ordering card readers",
        comment: "A label prompting users to learn more about card readers"
    )
}

struct InPersonPaymentsLearnMore_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLearnMore()
            .padding()
    }
}
