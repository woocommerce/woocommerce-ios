import SwiftUI

/// Reusable view for the Terms of Service label in the account creation forms.
struct AccountCreationTOSView: View {
    @State private var tosURL: URL?

    var body: some View {
        AttributedText(tosAttributedText, enablesLinkUnderline: true)
            .attributedTextLinkColor(Color(.secondaryLabel))
            .environment(\.customOpenURL) { url in
                tosURL = url
            }
            .safariSheet(url: $tosURL)
    }
}

private extension AccountCreationTOSView {
    var tosAttributedText: NSAttributedString {
        let result = NSMutableAttributedString(
            string: .localizedStringWithFormat(Localization.tosFormat, Localization.tos),
            attributes: [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.caption1
            ]
        )
        result.replaceFirstOccurrence(
            of: Localization.tos,
            with: NSAttributedString(
                string: Localization.tos,
                attributes: [
                    .font: UIFont.caption1,
                    .link: Constants.tosURL,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            ))
        return result
    }

    enum Constants {
        static let tosURL = WooConstants.URLs.termsOfService.asURL()
    }

    enum Localization {
        static let tosFormat = NSLocalizedString("By continuing, you agree to our %1$@.", comment: "Terms of service format on the account creation form.")
        static let tos = NSLocalizedString("Terms of Service", comment: "Terms of service link on the account creation form.")
    }
}

struct AccountCreationTOSView_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationTOSView()
    }
}
