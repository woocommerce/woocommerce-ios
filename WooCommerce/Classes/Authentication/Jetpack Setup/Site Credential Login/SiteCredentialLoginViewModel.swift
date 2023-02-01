import Foundation
import Yosemite
import WordPressAuthenticator

/// View model for `SiteCredentialLoginView`.
///
final class SiteCredentialLoginViewModel: ObservableObject {
    let siteURL: String

    @Published var username: String = ""
    @Published var password: String = ""
    @Published private(set) var primaryButtonDisabled = true
    @Published private(set) var isLoggingIn = false
    @Published private(set) var errorMessage = ""
    @Published var shouldShowErrorAlert = false

    private let analytics: Analytics
    private var useCase: SiteCredentialLoginProtocol?
    private let successHandler: () -> Void

    private var loginFields: LoginFields {
        let loginFields = LoginFields()
        loginFields.username = username
        loginFields.password = password
        loginFields.siteAddress = siteURL
        loginFields.meta.userIsDotCom = false
        return loginFields
    }

    init(siteURL: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         useCase: SiteCredentialLoginProtocol? = nil, // this is for mocking and testing
         onLoginSuccess: @escaping () -> Void = {}) {
        self.siteURL = siteURL
        self.analytics = analytics
        self.successHandler = onLoginSuccess
        self.useCase = useCase

        configurePrimaryButton()
        configureUseCase()
    }

    func handleLogin() {
        analytics.track(.loginJetpackSiteCredentialInstallTapped)
        useCase?.handleLogin(username: username, password: password)
    }

    func resetPassword() {
        analytics.track(.loginJetpackSiteCredentialResetPasswordTapped)
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
    }
}

// MARK: Private helpers
private extension SiteCredentialLoginViewModel {
    func configurePrimaryButton() {
        $username.combineLatest($password)
            .map { $0.isEmpty || $1.isEmpty }
            .assign(to: &$primaryButtonDisabled)
    }

    func configureUseCase() {
        useCase = SiteCredentialLoginUseCase(siteURL: siteURL, onLoading: { [weak self] isLoading in
            self?.isLoggingIn = isLoading
        }, onLoginSuccess: { [weak self] in
            self?.handleCompletion()
        }, onLoginFailure: { [weak self] error in
            self?.handleError(error)
        })
    }

    func handleError(_ error: SiteCredentialLoginError) {
        switch error {
        case .wrongCredentials:
            errorMessage = Localization.wrongCredentials
        case .genericFailure:
            errorMessage = Localization.genericFailure
        }
        shouldShowErrorAlert = true
        analytics.track(.loginJetpackSiteCredentialDidShowErrorAlert, withError: error.underlyingError)
    }

    func handleCompletion() {
        analytics.track(.loginJetpackSiteCredentialDidFinishLogin)
        successHandler()
    }
}

extension SiteCredentialLoginViewModel {
    enum Localization {
        static let wrongCredentials = NSLocalizedString(
            "It looks like this username/password isn't associated with this site.",
            comment: "An error message shown during login when the username or password is incorrect."
        )
        static let genericFailure = NSLocalizedString("Login failed. Please try again.", comment: "A generic error during site credential login")
    }
}
