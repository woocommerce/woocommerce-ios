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
        link: String,
        font: Font? = .body,
        foregroundColor: Color? = Color(uiColor: .text)
    ) -> AttributedString {
        let content = String.localizedStringWithFormat(mainContent, linkText)
        var attributedText = AttributedString(content)

        if let font {
            attributedText.font = font
        }
        if let foregroundColor {
            attributedText.foregroundColor = foregroundColor
        }

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

    /// Creates an attributed string with multiple embedded clickable links
    ///
    /// - Parameters:
    ///   - content: The content string with link text already inserted
    ///   - links: A dictionary mapping link text to URL strings
    ///   - font: Optional font for the text
    ///   - foregroundColor: Optional foreground color for non-link text
    /// - Returns: An AttributedString with proper styling and clickable links
    ///
    static func withEmbeddedLinks(
        content: String,
        links: [String: String],
        font: Font? = .body,
        foregroundColor: Color? = Color(uiColor: .text)
    ) -> AttributedString {
        var attributedText = AttributedString(content)

        if let font {
            attributedText.font = font
        }
        if let foregroundColor {
            attributedText.foregroundColor = foregroundColor
        }

        for (linkText, link) in links {
            if let range = attributedText.range(of: linkText),
               let url = URL(string: link) {
                var linkContainer = AttributeContainer()
                    .link(url)
                    .foregroundColor(Color.accentColor)
                linkContainer.underlineStyle = .single
                attributedText[range].mergeAttributes(linkContainer)
            }
        }

        return attributedText
    }
}
