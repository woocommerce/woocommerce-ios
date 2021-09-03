import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) var customOpenURL

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Image(uiImage: .infoOutlineImage)
                .resizable()
                .foregroundColor(Color(.textSubtle))
                .frame(width: iconSize, height: iconSize)
            AttributedText(Localization.learnMore)
                .font(.subheadline)
                .attributedTextForegroundColor(Color(.textSubtle))
                .attributedTextLinkColor(Color(.textLink))
                .customOpenURL { url in
                    ServiceLocator.analytics.track(.cardPresentOnboardingLearnMoreTapped)
                    customOpenURL?(url)
                }
        }
    }

    var iconSize: CGFloat {
        UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 20)
    }
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

    static let learnMore: NSAttributedString = {
        let learnMoreText = NSLocalizedString(
            "[Learn more](https://woocommerce.com/payments) about accepting payments with your mobile device and ordering card readers",
            comment: "A label prompting users to learn more about card readers with an embedded hyperlink"
        )

        let learnMoreAttributes: [NSAttributedString.Key: Any] = [
            .font: StyleManager.footerLabelFont,
            .foregroundColor: UIColor.textSubtle
        ]

        let learnMoreAttrText = try! NSMutableAttributedString(markdown: learnMoreText)
        let range = NSRange(location: 0, length: learnMoreAttrText.length)
        learnMoreAttrText.addAttributes(learnMoreAttributes, range: range)

        return learnMoreAttrText
    }()
}

struct InPersonPaymentsLearnMore_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLearnMore()
            .padding()
    }
}
