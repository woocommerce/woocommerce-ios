import Combine
import Foundation
import struct Yosemite.CreateAccountResult
import enum Yosemite.Credentials
import enum Yosemite.AccountAction
import enum Yosemite.AccountCreationAction
import enum Yosemite.CreateAccountError
import protocol Yosemite.StoresManager
import class WordPressShared.EmailFormatValidator
import WordPressAuthenticator

/// View model for `AccountCreationForm` view.
final class AccountCreationFormViewModel: ObservableObject {
    /// Email input.
    @Published var email: String = ""
    /// An error can come from the WPCOM backend, when the email is invalid or already exists.
    @Published private(set) var emailErrorMessage: String?
    /// Local validation on the email field.
    @Published private(set) var isEmailValid: Bool = false

    /// Password input.
    @Published var password: String = ""
    /// An error can come from the WPCOM backend, when the password is too simple.
    @Published private(set) var passwordErrorMessage: String?
    /// Local validation on the password field.
    @Published private(set) var isPasswordValid: Bool = false

    private let stores: StoresManager
    private let analytics: Analytics
    private let accountService: WordPressComAccountServiceProtocol
    private let onPasswordUIRequest: ((_ email: String) -> Void)?
    private let onMagicLinkUIRequest: ((_ email: String) -> Void)?
    private let emailSubmissionHandler: ((_ email: String) -> Void)?
    private var subscriptions: Set<AnyCancellable> = []

    init(email: String = "",
         debounceDuration: Double = Constants.fieldDebounceDuration,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onPasswordUIRequest: ((_ email: String) -> Void)? = nil,
         onMagicLinkUIRequest: ((_ email: String) -> Void)? = nil,
         emailSubmissionHandler: ((_ email: String) -> Void)? = nil) {
        self.accountService = accountService
        self.stores = stores
        self.analytics = analytics
        self.email = email
        self.onPasswordUIRequest = onPasswordUIRequest
        self.onMagicLinkUIRequest = onMagicLinkUIRequest
        self.emailSubmissionHandler = emailSubmissionHandler

        $email
            .removeDuplicates()
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }.store(in: &subscriptions)

        $password
            .removeDuplicates()
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] password in
                self?.validatePassword(password)
            }.store(in: &subscriptions)
    }

    /// Creates a WPCOM account with the email and password.
    /// - Returns: async result of account creation.
    @MainActor
    func createAccount() async throws {
        analytics.track(event: .StoreCreation.signupSubmitted())

        do {
            let data = try await withCheckedThrowingContinuation { continuation in
                let action = AccountCreationAction.createAccount(email: email, password: password) { result in
                    continuation.resume(with: result)
                }
                stores.dispatch(action)
            }

            analytics.track(event: .StoreCreation.signupSuccess())

            await handleSuccess(data: data)
        } catch let error as CreateAccountError {
            /// Skip tracking if the password field is yet to be presented.
            let shouldSkipTrackingError: Bool = {
                guard case .invalidPassword = error else {
                    return false
                }
                return emailSubmissionHandler != nil
            }()
            if !shouldSkipTrackingError {
                analytics.track(event: .StoreCreation.signupFailed(error: error))
            }
            await handleFailure(error: error)

            throw error
        }
    }
}

private extension AccountCreationFormViewModel {
    @MainActor
    func handleSuccess(data: CreateAccountResult) async {
        await withCheckedContinuation { continuation in
            stores.authenticate(credentials: .init(username: data.username, authToken: data.authToken))
                .synchronizeEntities(onCompletion: {
                    continuation.resume(returning: ())
                })
        }
    }

    @MainActor
    func handleFailure(error: CreateAccountError) async {
        switch error {
        case .emailExists:
            await checkWordPressComAccount(email: email)
        case .invalidEmail:
            emailErrorMessage = Localization.invalidEmailError
        case .invalidPassword(let message):
            if let handler = emailSubmissionHandler {
                handler(email)
            } else {
                passwordErrorMessage = message ?? Localization.passwordError
            }
        default:
            break
        }
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
            emailErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func startAuthentication(email: String, isPasswordlessAccount: Bool) async {
        if isPasswordlessAccount {
            await requestAuthenticationLink(email: email)
        } else {
            onPasswordUIRequest?(email)
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
            onMagicLinkUIRequest?(email)
        } catch {
            emailErrorMessage = error.localizedDescription
        }
    }
}

private extension AccountCreationFormViewModel {
    func validateEmail(_ email: String) {
        isEmailValid = EmailFormatValidator.validate(string: email)
        emailErrorMessage = nil
    }

    func validatePassword(_ password: String) {
        isPasswordValid = password.count >= 6
        passwordErrorMessage = nil
    }
}

private extension AccountCreationFormViewModel {
    enum Constants {
        static let fieldDebounceDuration = 0.3
    }

    enum Localization {
        static let invalidEmailError = NSLocalizedString("Use a working email address, so you can receive our messages.",
                                                         comment: "Account creation error when the email is invalid.")
        static let passwordError = NSLocalizedString("Password must be at least 6 characters.",
                                                     comment: "Account creation error when the password is invalid.")
        static let otherError = NSLocalizedString("Please try again.",
                                                  comment: "Account creation error when an unexpected error occurs.")
    }
}
