import Foundation
import UIKit

/// View model for `WPComEmailLoginView`
final class WPComEmailLoginViewModel: ObservableObject {
    @Published var emailAddress: String = ""

    let termsAttributedString: NSAttributedString

    /// The closure to be triggered when the Install Jetpack button is tapped.
    private let onSubmit: (String) -> Void

    init(siteURL: String, onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        self.termsAttributedString = {
            let content = String.localizedStringWithFormat(Localization.termsContent, Localization.termsOfService, Localization.shareDetails)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let mutableAttributedText = NSMutableAttributedString(
                string: content,
                attributes: [.font: UIFont.footnote,
                             .foregroundColor: UIColor.secondaryLabel,
                             .paragraphStyle: paragraph]
            )

            mutableAttributedText.setAsLink(textToFind: Localization.termsOfService,
                                            linkURL: Constants.jetpackTermsURL + siteURL)
            mutableAttributedText.setAsLink(textToFind: Localization.shareDetails,
                                            linkURL: Constants.jetpackShareDetailsURL + siteURL)
            return mutableAttributedText
        }()
    }

    func handleSubmission() {
        // TODO
    }
}

private extension WPComEmailLoginViewModel {
    enum Constants {
        static let jetpackTermsURL = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetailsURL = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
    }

    enum Localization {
        static let termsContent = NSLocalizedString(
            "By tapping the Install Jetpack button, you agree to our %1$@ and to %2$@ with WordPress.com.",
            comment: "Content of the label at the end of the Wrong Account screen. " +
            "Reads like: By tapping the Connect Jetpack button, you agree to our Terms of Service and to share details with WordPress.com.")
        static let termsOfService = NSLocalizedString(
            "Terms of Service",
            comment: "The terms to be agreed upon when tapping the Connect Jetpack button on the Wrong Account screen."
        )
        static let shareDetails = NSLocalizedString(
            "share details",
            comment: "The action to be agreed upon when tapping the Connect Jetpack button on the Wrong Account screen."
        )
    }
}
