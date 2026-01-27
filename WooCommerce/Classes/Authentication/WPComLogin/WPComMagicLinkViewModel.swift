import SwiftUI

/// View model for `WPComMagicLinkView`
///
final class WPComMagicLinkViewModel {

    /// Text for the instruction
    let instructionString: AttributedString

    init(email: String) {
        self.instructionString = {
            let content = String.localizedStringWithFormat(Localization.sentLink, email)
            var attributedText = AttributedString(content)
            attributedText.font = .body
            attributedText.foregroundColor = Color(.text)

            if let range = attributedText.range(of: email) {
                attributedText[range].font = .body.bold()
            }
            return attributedText
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
