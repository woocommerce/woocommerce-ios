import UIKit

/// View model for `WPComMagicLinkView`
///
final class WPComMagicLinkViewModel {

    /// Text for the instruction
    let instructionString: NSAttributedString

    init(email: String) {
        self.instructionString = {
            let font: UIFont = .body
            let boldFont: UIFont = font.bold

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let boldSiteAddress = NSAttributedString(string: email, attributes: [.font: boldFont, .foregroundColor: UIColor.text.cgColor])
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.text.cgColor
            ]
            let message = NSMutableAttributedString(string: Localization.sentLink, attributes: attributes)
            message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

            return message
        }()
    }
}

extension WPComMagicLinkViewModel {
    enum Localization {
        static let sentLink = NSLocalizedString(
            "We just sent a magic link to %@",
            comment: "Instruction on the magic link screen of the WPCom login flow during Jetpack setup. " +
            "%@ is a submitted email address."
        )
    }
}
