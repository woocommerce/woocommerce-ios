import SwiftUI

struct InPersonPaymentsUnavailableView: View {
    @State var presentedURL: URL? = nil

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.unavailable)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Image(uiImage: .paymentErrorImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180.0)
                Text(Localization.acceptCash)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack(alignment: .center, spacing: 20) {
                Image(uiImage: .infoOutlineImage)
                    .accentColor(Color(.lightGray))
                    .frame(width: 20, height: 20)
                AttributedText(Localization.learnMore)
                    .accentColor(Color(.textLink))
                    .customOpenURL(binding: $presentedURL)
            }
        }
        .safariSheet(url: $presentedURL)
        .padding(24.0)
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

    static var learnMore: NSAttributedString {
        let learnMoreText = NSLocalizedString(
            "<a href=\"https://woocommerce.com/payments\">Learn more</a> about accepting payments with your mobile device and ordering card readers",
            comment: "A label prompting users to learn more about card readers with an embedded hyperlink"
        )

        let learnMoreAttributes: [NSAttributedString.Key: Any] = [
            .font: StyleManager.footerLabelFont,
            .foregroundColor: UIColor.textSubtle
        ]

        let learnMoreAttrText = NSMutableAttributedString()
        learnMoreAttrText.append(learnMoreText.htmlToAttributedString)
        let range = NSRange(location: 0, length: learnMoreAttrText.length)
        learnMoreAttrText.addAttributes(learnMoreAttributes, range: range)

        return learnMoreAttrText
    }
}

struct InPersonPaymentsUnavailableView_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsUnavailableView()
    }
}
