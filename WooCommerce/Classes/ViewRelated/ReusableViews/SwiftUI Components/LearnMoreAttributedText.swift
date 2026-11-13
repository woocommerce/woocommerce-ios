import SwiftUI

/// Displays an attributed text where a "learn more" or any other substring is tappable in a longer text.
struct LearnMoreAttributedText: View {
    private let attributedLearnMoreText: AttributedString
    private let urlHandler: LearnMoreAttributedTextURLHandler
    @State private var presentedURL: URL?

    /// - Parameters:
    ///   - format: A format string with one variable for the learn more text.
    ///   - learnMoreText: A string that is tappable for the user to learn more.
    ///   - url: URL to display in a Safari sheet when the learn more text is tapped without a custom action.
    ///   - shouldUnderLine: The tappable text will be underlined if `true`. Default value is `true`
    ///   - textColor: The foreground text color. Default value is `.textSubtle`
    ///   - linkTextColor: The tappable text color. Default value is `.accent`
    ///   - onTapURL: Optional custom action when the tappable text is tapped. Defaults to showing the URL in a Safari sheet.
    init(format: String,
         tappableLearnMoreText learnMoreText: String,
         url: URL,
         shouldUnderLine: Bool = true,
         textColor: UIColor = .textSubtle,
         linkTextColor: UIColor = .accent,
         onTapURL: ((URL) -> Void)? = nil) {
        self.urlHandler = LearnMoreAttributedTextURLHandler(expectedURL: url, onTapURL: onTapURL)
        attributedLearnMoreText = {
            var attributedText = AttributedString(.init(format: format, learnMoreText))
            attributedText.font = .footnote
            attributedText.foregroundColor = .init(textColor)

            // Link styles for the learn more string.
            if let range = attributedText.range(of: learnMoreText) {
                var linkContainer = AttributeContainer()
                    .link(url)
                    .foregroundColor(.init(uiColor: linkTextColor))
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
                switch urlHandler.handle(url, presentURL: { presentedURL = $0 }) {
                case .handled:
                    return .handled
                case .systemAction:
                    return .systemAction
                }
            })
            .safariSheet(url: $presentedURL)
    }
}

struct LearnMoreAttributedTextURLHandler {
    enum Result: Equatable {
        case handled
        case systemAction
    }

    let expectedURL: URL
    let onTapURL: ((URL) -> Void)?

    func handle(_ url: URL, presentURL: (URL) -> Void) -> Result {
        guard url == expectedURL else {
            return .systemAction
        }

        if let onTapURL {
            onTapURL(url)
        } else {
            presentURL(url)
        }
        return .handled
    }
}

struct LearnMoreAttributedText_Previews: PreviewProvider {
    static var previews: some View {
        LearnMoreAttributedText(format: "%1$@ about dev.",
                                tappableLearnMoreText: "Learn more",
                                url: .init(string: "https://developer.apple.com")!)
    }
}
