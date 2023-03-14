import Combine
import UIKit
import WordPressAuthenticator

/// A protocol used to mock `WordPressComAccountService` for unit tests.
protocol WordPressComAccountServiceProtocol {
    func isPasswordlessAccount(username: String, success: @escaping (Bool) -> Void, failure: @escaping (Error) -> Void)
    func requestAuthenticationLink(for email: String, jetpackLogin: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
}

/// Conformance
extension WordPressComAccountService: WordPressComAccountServiceProtocol {}

/// View model for `WPComEmailLoginView`
final class WPComEmailLoginViewModel: ObservableObject {
    let titleString: String
    let subtitleString: String

    @Published var emailAddress: String = ""

    let termsAttributedString: NSAttributedString

    private let accountService: WordPressComAccountServiceProtocol
    private let onPasswordUIRequest: (String) -> Void
    private let onMagicLinkUIRequest: (String) -> Void
    private let onError: (String) -> Void

    private var emailFieldSubscription: AnyCancellable?

    init(siteURL: String,
         requiresConnectionOnly: Bool,
         debounceDuration: Double = Constants.fieldDebounceDuration,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         onPasswordUIRequest: @escaping (String) -> Void,
         onMagicLinkUIRequest: @escaping (String) -> Void,
         onError: @escaping (String) -> Void) {
        self.accountService = accountService
        self.onPasswordUIRequest = onPasswordUIRequest
        self.onMagicLinkUIRequest = onMagicLinkUIRequest
        self.onError = onError

        self.titleString = requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
        self.subtitleString = requiresConnectionOnly ? Localization.loginToConnect : Localization.loginToInstall
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

    @MainActor
    func checkWordPressComAccount(email: String) async {
        do {
            let passwordless = try await withCheckedThrowingContinuation { continuation in
                accountService.isPasswordlessAccount(username: email, success: { passwordless in
                    continuation.resume(returning: passwordless)
                }, failure: { error in
                    DDLogError("⛔️ Error checking for passwordless account: \(error)")
                    continuation.resume(throwing: error)
                })
            }
            await startAuthentication(email: email, isPasswordlessAccount: passwordless)
        } catch {
            onError(error.localizedDescription)
        }
    }

    @MainActor
    private func startAuthentication(email: String, isPasswordlessAccount: Bool) async {
        if isPasswordlessAccount {
            await requestAuthenticationLink(email: email)
        } else {
            onPasswordUIRequest(email)
        }
    }

    @MainActor
    func requestAuthenticationLink(email: String) async {
        do {
            try await withCheckedThrowingContinuation { continuation in
                accountService.requestAuthenticationLink(for: email, jetpackLogin: false, success: {
                    continuation.resume()
                }, failure: { error in
                    continuation.resume(throwing: error)
                })
            }
            onMagicLinkUIRequest(email)
        } catch {
            onError(error.localizedDescription)
        }
    }
}

extension WPComEmailLoginViewModel {
    private enum Constants {
        static let fieldDebounceDuration = 0.3
        static let jetpackTermsURL = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetailsURL = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
        static let wpcomErrorCodeKey = "WordPressComRestApiErrorCodeKey"
    }

    enum Localization {
        static let installJetpack = NSLocalizedString(
            "Install Jetpack",
            comment: "Title for the WPCom email login screen when Jetpack is not installed yet"
        )
        static let loginToInstall = NSLocalizedString(
            "Log in with your WordPress.com account to install Jetpack",
            comment: "Subtitle for the WPCom email login screen when Jetpack is not installed yet"
        )
        static let connectJetpack = NSLocalizedString(
            "Connect Jetpack",
            comment: "Title for the WPCom email login screen when Jetpack is not connected yet"
        )
        static let loginToConnect = NSLocalizedString(
            "Log in with your WordPress.com account to connect Jetpack",
            comment: "Subtitle for the WPCom email login screen when Jetpack is not connected yet"
        )
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
