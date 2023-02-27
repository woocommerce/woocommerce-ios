import Combine
import UIKit
import WordPressShared

/// View model for `WPComEmailLoginView`
final class WPComEmailLoginViewModel: ObservableObject {
    @Published var emailAddress: String = ""
    /// Local validation on the email field.
    @Published private(set) var isEmailValid: Bool = false

    let termsAttributedString: NSAttributedString

    private var emailFieldSubscription: AnyCancellable?

    init(siteURL: String,
         debounceDuration: Double = Constants.fieldDebounceDuration) {
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
        observeEmailField(debounceDuration: debounceDuration)
    }
}

private extension WPComEmailLoginViewModel {
    func observeEmailField(debounceDuration: Double) {
        emailFieldSubscription = $emailAddress
            .removeDuplicates()
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }
    }

    func validateEmail(_ email: String) {
        isEmailValid = EmailFormatValidator.validate(string: email)
    }
}

private extension WPComEmailLoginViewModel {
    enum Constants {
        static let fieldDebounceDuration = 0.3
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
