import Foundation
import UIKit

struct LearnMoreViewModel {

    static let learnMoreURL = URL(string: "woocommerce://in-person-payments/learn-more")!

    let url: URL
    let linkText: String
    let formatText: String
    let tappedAnalyticEvent: WooAnalyticsEvent?

    init(url: URL = learnMoreURL,
         linkText: String = Localization.learnMoreLink,
         formatText: String = Localization.learnMoreText,
         tappedAnalyticEvent: WooAnalyticsEvent? = nil) {
        self.url = url
        self.linkText = linkText
        self.formatText = formatText
        self.tappedAnalyticEvent = tappedAnalyticEvent
    }

    var learnMoreAttributedString: NSAttributedString {
        let result = NSMutableAttributedString(
            string: .localizedStringWithFormat(formatText, linkText),
            attributes: [.foregroundColor: UIColor.textSubtle]
        )
        result.replaceFirstOccurrence(
            of: linkText,
            with: NSAttributedString(
                string: linkText,
                attributes: [.foregroundColor: UIColor.textLink]
            ))

        // https://github.com/gonzalezreal/AttributedText/issues/11
        result.addAttribute(.font, value: UIFont.footnote, range: NSRange(location: 0, length: result.length))
        return result
    }

    func learnMoreTapped() {
        guard let tappedAnalyticEvent = tappedAnalyticEvent else {
            return
        }

        ServiceLocator.analytics.track(event: tappedAnalyticEvent)
    }
}

private enum Localization {
    static let learnMoreLink = NSLocalizedString(
        "Learn more",
        comment: """
                 A label prompting users to learn more about card readers.
                 This part is the link to the website, and forms part of a longer sentence which it should be considered a part of.
                 """
    )

    static let learnMoreText = NSLocalizedString(
        "%1$@ about accepting payments with your mobile device and ordering card readers",
        comment: """
                 A label prompting users to learn more about card readers"
                 %1$@ is a placeholder that always replaced with \"Learn more\" string,
                 which should be translated separately and considered part of this sentence.
                 """
    )
}
