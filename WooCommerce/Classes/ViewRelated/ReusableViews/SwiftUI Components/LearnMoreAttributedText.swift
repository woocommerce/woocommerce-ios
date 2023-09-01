import SwiftUI

/// Displays an attributed text where a "learn more" or any other substring is tappable in a longer text to show a Safari sheet.
struct LearnMoreAttributedText: View {
    private let attributedLearnMoreText: AttributedString
    @State private var learnMoreURL: URL?

    /// - Parameters:
    ///   - format: A format string with one variable for the learn more text.
    ///   - learnMoreText: A string that is tappable that opens a Safari sheet for the user to learn more.
    ///   - url: URL to display in a Safari sheet when the learn more text is tapped.
    ///   - shouldUnderLine: The tappable text will be underlined if `true`. Default value is `true`
    ///   - textColor: The foreground text color. Default value is `.textSubtle`
    init(format: String,
         tappableLearnMoreText learnMoreText: String,
         url: URL,
         shouldUnderLine: Bool = true,
         textColor: UIColor = .textSubtle) {
        attributedLearnMoreText = {
            var attributedText = AttributedString(.init(format: format, learnMoreText))
            attributedText.font = .footnote
            attributedText.foregroundColor = .init(textColor)

            // Link styles for the learn more string.
            if let range = attributedText.range(of: learnMoreText) {
                var linkContainer = AttributeContainer()
                    .link(url)
                    .foregroundColor(.init(uiColor: .accent))
                if shouldUnderLine {
                    linkContainer.underlineStyle = .single
                }
                attributedText[range].mergeAttributes(linkContainer)
            }
            return attributedText
        }()
    }

    var body: some View {
        Text(attributedLearnMoreText)
            .environment(\.openURL, OpenURLAction { url in
                learnMoreURL = url
                return .handled
            })
            .safariSheet(url: $learnMoreURL)
    }
}

struct LearnMoreAttributedText_Previews: PreviewProvider {
    static var previews: some View {
        LearnMoreAttributedText(format: "%1$@ about dev.",
                                tappableLearnMoreText: "Learn more",
                                url: .init(string: "https://developer.apple.com")!)
    }
}
