import SwiftUI

struct InPersonPaymentsSupportLink: View {
    static let supportURL = URL(string: "woocommerce://contact-us")!

    var body: some View {
        AttributedText(supportAttributedString)
            .attributedTextForegroundColor(Color(.text))
            .attributedTextLinkColor(Color(.textLink))
    }

    private var supportAttributedString: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let commonAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.callout,
            .foregroundColor: UIColor.text,
            .paragraphStyle: paragraphStyle
        ]
        let result = NSMutableAttributedString()
        result.append(
            NSAttributedString(
                string: Localization.needHelp,
                attributes: commonAttributes
            )
        )
        result.append(
            NSMutableAttributedString(
                string: .space,
                attributes: commonAttributes
            )
        )
        result.append(
            NSAttributedString(
                string: Localization.contactUs,
                attributes: commonAttributes.merging([
                    .link: InPersonPaymentsSupportLink.supportURL
                ], uniquingKeysWith: { $1 })
            )
        )
        return result
    }
}

private enum Localization {
    static let needHelp = NSLocalizedString(
        "Need some help?",
        comment: "Text preceding the Contact Us button in the error screen for In-Person payments"
    )

    static let contactUs = NSLocalizedString(
        "Contact us",
        comment: "Title of a button to contact support in the error screen for In-Person payments"
    )
}

struct InPersonPaymentsSupportLink_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsSupportLink()
    }
}
