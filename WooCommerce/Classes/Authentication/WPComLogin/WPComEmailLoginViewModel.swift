import Combine
import SwiftUI
import WordPressAuthenticator
import protocol WooFoundation.Analytics

/// A protocol used to mock `WordPressComAccountService` for unit tests.
protocol WordPressComAccountServiceProtocol {
    func isPasswordlessAccount(username: String, success: @escaping (Bool) -> Void, failure: @escaping (Error) -> Void)
    func requestAuthenticationLink(for email: String,
                                   jetpackLogin: Bool,
                                   createAccountIfNotFound: Bool,
                                   success: @escaping () -> Void,
                                   failure: @escaping (Error) -> Void)
}

/// Conformance
extension WordPressComAccountService: WordPressComAccountServiceProtocol {}

/// View model for `WPComEmailLoginView`
final class WPComEmailLoginViewModel: ObservableObject {
    var titleString: String {
        switch flow {
        case .notificationSetup:
            Localization.ConnectWPCom.title
        case .jetpackSetup(let requiresConnectionOnly):
            requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
        }
    }

    var subtitleString: String {
        switch flow {
        case .notificationSetup:
            Localization.ConnectWPCom.subtitle
        case .jetpackSetup(let requiresConnectionOnly):
            requiresConnectionOnly ? Localization.loginToConnect : Localization.loginToInstall
        }
    }

    var primaryButtonTitle: String {
        switch flow {
        case .notificationSetup:
            Localization.ConnectWPCom.primaryButtonTitle
        case .jetpackSetup:
            titleString
        }
    }

    let flow: WPComLoginFlow

    @Published var emailOrUsername: String = ""
    @Published var usernameOnly: Bool = false

    let termsAttributedString: AttributedString

    let allowAccountCreation: Bool
    private let accountService: WordPressComAccountServiceProtocol
    private let analytics: Analytics
    private let onPasswordUIRequest: (String) -> Void
    private let onMagicLinkRequest: (String) -> Void
    private let onMagicLinkSent: (_ email: String, _ isSignup: Bool) -> Void
    private let onError: (String) -> Void

    private var emailFieldSubscription: AnyCancellable?

    init(siteURL: String,
         flow: WPComLoginFlow,
         allowAccountCreation: Bool,
         debounceDuration: Double = Constants.fieldDebounceDuration,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         analytics: Analytics = ServiceLocator.analytics,
         onPasswordUIRequest: @escaping (String) -> Void,
         onMagicLinkRequest: @escaping (String) -> Void,
         onMagicLinkSent: @escaping (String, Bool) -> Void,
         onError: @escaping (String) -> Void) {
        self.allowAccountCreation = allowAccountCreation
        self.analytics = analytics
        self.accountService = accountService
        self.onPasswordUIRequest = onPasswordUIRequest
        self.onMagicLinkRequest = onMagicLinkRequest
        self.onMagicLinkSent = onMagicLinkSent
        self.onError = onError
        self.flow = flow
        self.termsAttributedString = {
            let content: String = {
                switch flow {
                case .notificationSetup:
                    String.localizedStringWithFormat(Localization.ConnectWPCom.termsContent, Localization.termsOfService, Localization.shareDetails)
                case .jetpackSetup:
                    String.localizedStringWithFormat(Localization.termsContent, Localization.termsOfService, Localization.shareDetails)
                }
            }()

            let attributedText = AttributedString.withEmbeddedLinks(
                content: content,
                links: [
                    Localization.termsOfService: Constants.jetpackTermsURL + siteURL,
                    Localization.shareDetails: Constants.jetpackShareDetailsURL + siteURL
                ],
                font: .footnote,
                foregroundColor: .secondary
            )
            return attributedText
        }()
    }

    @MainActor
    func checkWordPressComAccount(emailOrUsername: String) async {
        do {
            let passwordless = try await withCheckedThrowingContinuation { continuation in
                accountService.isPasswordlessAccount(username: emailOrUsername, success: { passwordless in
                    continuation.resume(returning: passwordless)
                }, failure: { error in
                    DDLogError("⛔️ Error checking for passwordless account: \(error)")
                    continuation.resume(throwing: error)
                })
            }
            await startAuthentication(emailOrUsername: emailOrUsername, isPasswordlessAccount: passwordless)
        } catch {
            let apiErrorCode: String? = {
                if let apiError = error as? WordPressAPIError<WordPressComRestApiEndpointError>,
                   case .endpointError(let endpointError) = apiError {
                    return endpointError.apiErrorCode
                }
                return nil
            }()

            if allowAccountCreation,
               apiErrorCode == Constants.unknownUserErrorCode {
                await handleUnkownUserError(emailOrUsername: emailOrUsername, error: error)
                return
            }

            if apiErrorCode == Constants.emailNotAllowed {
                onMagicLinkRequest(emailOrUsername)
                return
            }

            analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress, failure: error))
            onError(error.localizedDescription)
        }
    }

    @MainActor
    private func startAuthentication(emailOrUsername: String, isPasswordlessAccount: Bool) async {
        if isPasswordlessAccount {
            await requestAuthenticationLink(email: emailOrUsername)
        } else {
            onPasswordUIRequest(emailOrUsername)
        }
    }

    @MainActor
    func requestAuthenticationLink(email: String, forAccountCreation: Bool = false) async {
        do {
            try await withCheckedThrowingContinuation { continuation in
                accountService.requestAuthenticationLink(for: email,
                                                         jetpackLogin: false,
                                                         createAccountIfNotFound: forAccountCreation,
                                                         success: {
                    continuation.resume()
                }, failure: { error in
                    continuation.resume(throwing: error)
                })
            }
            onMagicLinkSent(email, forAccountCreation)
        } catch {
            onError(error.localizedDescription)
            analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress, isSignup: forAccountCreation, failure: error))
        }
    }
}

private extension WPComEmailLoginViewModel {
    @MainActor
    func handleUnkownUserError(emailOrUsername: String, error: Error) async {
        guard emailOrUsername.isValidEmail() else {
            analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress, failure: error))
            onError(Localization.unknownUsername)
            return
        }

        await requestAuthenticationLink(email: emailOrUsername, forAccountCreation: true)
    }
}

extension WPComEmailLoginViewModel {
    private enum Constants {
        static let fieldDebounceDuration = 0.3
        static let jetpackTermsURL = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetailsURL = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
        static let wpcomErrorCodeKey = "WordPressComRestApiErrorCodeKey"
        static let unknownUserErrorCode = "unknown_user"
        static let emailNotAllowed = "email_login_not_allowed"
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
            comment: "Button text that appears on the site credential login screen to initiate connecting Jetpack to a WooCommerce store, and also used as a navigation title for the Jetpack connection web view and as an action button when resolving account connection issues."
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
        static let unknownUsername = NSLocalizedString(
            "wpComEmailLoginViewModel.unknownUsername",
            value: "We can\'t find a WordPress.com account connected to this username. You can enter an email to create a new account.",
            comment: "Error message when the username is not found"
        )

        enum ConnectWPCom {
            static let title = NSLocalizedString(
                "wpcomEmailLoginViewModel.connectWPCom.title",
                value: "Connect to WordPress.com",
                comment: "Title for the WPCom email login screen for push notification setup"
            )
            static let subtitle = NSLocalizedString(
                "wpcomEmailLoginViewModel.connectWPCom.subtitle",
                value: "Log in with your WordPress.com account to connect your store.",
                comment: "Subtitle for the WPCom email login screen for push notification setup"
            )
            static let primaryButtonTitle = NSLocalizedString(
                "wpcomEmailLoginViewModel.connectWPCom.primaryButtonTitle",
                value: "Continue",
                comment: "Button to submit a WPCom email on the login screen for push notification setup"
            )
            static let termsContent = NSLocalizedString(
                "wpcomEmailLoginViewModel.connectWPCom.termsContent",
                value: "By continuing, you agree to our %1$@ and to %2$@ with WordPress.com.",
                comment: "Content of the label at the end of the Wrong Account screen. " +
                "Reads like: By tapping the Connect Jetpack button, you agree to our Terms of Service and to share details with WordPress.com.")
        }
    }
}
