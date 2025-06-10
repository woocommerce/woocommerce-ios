import Foundation
import SwiftUI

/// AttributedString: Helper Methods
///
extension AttributedString {

    /// Creates an attributed string with an embedded clickable link
    ///
    /// - Parameters:
    ///   - mainContent: The main content string with a placeholder (e.g., "I agree to %@")
    ///   - linkText: The text that should become a clickable link
    ///   - link: The URL string for the link
    /// - Returns: An AttributedString with proper styling and a clickable link
    ///
    static func withEmbeddedLink(
        mainContent: String,
        linkText: String,
        link: String
    ) -> AttributedString {
        let content = String.localizedStringWithFormat(mainContent, linkText)
        var attributedText = AttributedString(content)
        attributedText.font = .body
        attributedText.foregroundColor = Color(uiColor: .text)

        if let range = attributedText.range(of: linkText),
           let url = URL(string: link) {
            var linkContainer = AttributeContainer()
                .link(url)
                .foregroundColor(Color.accentColor)
            linkContainer.underlineStyle = .single
            attributedText[range].mergeAttributes(linkContainer)
        }
        return attributedText
    }
}
