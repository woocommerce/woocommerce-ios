import Combine
import UIKit
import WordPressShared
import WordPressAuthenticator

/// View model for `WPComEmailLoginView`
final class WPComEmailLoginViewModel: ObservableObject {
    let titleString: String
    let subtitleString: String

    @Published var emailAddress: String = ""
    /// Local validation on the email field.
    @Published private(set) var isEmailValid: Bool = false

    let termsAttributedString: NSAttributedString

    private let accountService: WordPressComAccountService
    private let onPasswordUIRequest: (String) -> Void
    private let onMagicLinkUIRequest: (String) -> Void
    private let onError: (String) -> Void

    private var emailFieldSubscription: AnyCancellable?

    init(siteURL: String,
         requiresConnectionOnly: Bool,
         debounceDuration: Double = Constants.fieldDebounceDuration,
         onPasswordUIRequest: @escaping (String) -> Void,
         onMagicLinkUIRequest: @escaping (String) -> Void,
         onError: @escaping (String) -> Void) {
        self.accountService = WordPressComAccountService()
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
        observeEmailField(debounceDuration: debounceDuration)
    }

    @MainActor
    func checkWordPressComAccount(email: String) async {
        await withCheckedContinuation { continuation -> Void in
            accountService.isPasswordlessAccount(username: email, success: { [weak self] passwordless in
                guard let self else {
                    return continuation.resume()
                }
                self.startAuthentication(email: email, isPasswordlessAccount: passwordless) {
                    continuation.resume()
                }
            }, failure: { [weak self] error in
                DDLogError("⛔️ Error checking for passwordless account: \(error)")
                continuation.resume()
                self?.handleAccountCheckError(error)
            })
        }
    }

    func startAuthentication(email: String, isPasswordlessAccount: Bool, onCompletion: @escaping () -> Void) {
        if isPasswordlessAccount {
            Task { @MainActor in
                await requestAuthenticationLink(email: email)
                onCompletion()
            }
        } else {
            onPasswordUIRequest(email)
            onCompletion()
        }
    }

    @MainActor
    func requestAuthenticationLink(email: String) async {
        await withCheckedContinuation { continuation in
            accountService.requestAuthenticationLink(for: email, jetpackLogin: false, success: { [weak self] in
                guard let self else {
                    return continuation.resume()
                }
                self.onMagicLinkUIRequest(email)
                continuation.resume()
            }, failure: { [weak self] error in
                guard let self else {
                    return continuation.resume()
                }
                self.onError(error.prepareErrorMessage(fallback: Localization.errorRequestingAuthURL))
                continuation.resume()
            })
        }
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

    /// Handles the result of `accountService`'s `isPasswordlessAccount`.
    /// The implementation follows what have been done in `WordPressAuthenticator`.
    /// Please update this when the API changes.
    ///
    func handleAccountCheckError(_ error: Error) {
        let userInfo = (error as NSError).userInfo
        let errorCode = userInfo[Constants.wpcomErrorCodeKey] as? String

        if errorCode == Constants.emailLoginNotAllowedCode {
            // If we get this error, we know we have a WordPress.com user but their
            // email address is flagged as suspicious.  They need to login via their
            // username instead.
            #warning("TODO: handle username login")
        } else {
            onError(error.prepareErrorMessage(fallback: Localization.errorCheckingWPComAccount))
        }
    }
}

extension WPComEmailLoginViewModel {
    private enum Constants {
        static let fieldDebounceDuration = 0.3
        static let jetpackTermsURL = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetailsURL = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
        static let wpcomErrorCodeKey = "WordPressComRestApiErrorCodeKey"
        static let emailLoginNotAllowedCode = "email_login_not_allowed"
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
        static let errorCheckingWPComAccount = NSLocalizedString(
            "Error checking the WordPress.com account associated with this email. Please try again.",
            comment: "Message shown on the error alert displayed when checking Jetpack connection fails during the Jetpack setup flow."
        )
        static let errorRequestingAuthURL = NSLocalizedString(
            "Error requesting authentication link for your account. Please try again.",
            comment: "Message shown on the error alert displayed when requesting authentication link for the Jetpack setup flow fails"
        )
    }
}
