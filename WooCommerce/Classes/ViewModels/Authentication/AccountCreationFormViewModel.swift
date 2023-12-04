import Combine
import Foundation
import struct Yosemite.CreateAccountResult
import enum Yosemite.Credentials
import enum Yosemite.AccountAction
import enum Yosemite.AccountCreationAction
import enum Yosemite.CreateAccountError
import protocol Yosemite.StoresManager
import class WordPressShared.EmailFormatValidator

/// View model for `AccountCreationForm` view.
final class AccountCreationFormViewModel: ObservableObject {
    enum Field: Equatable {
        case email
        case password
    }

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

    @Published private(set) var isPerformingTask = false
    @Published private(set) var currentField: Field = .email
    @Published private(set) var shouldTransitionToPasswordField = false

    private let stores: StoresManager
    private let analytics: Analytics
    private let onExistingEmail: ((_ email: String) async -> Void)
    private let completionHandler: (() -> Void)
    private var subscriptions: Set<AnyCancellable> = []

    var isSubmitButtonDisabled: Bool {
        switch currentField {
        case .email:
            return !isEmailValid || isPerformingTask
        case .password:
            return !isPasswordValid || isPerformingTask
        }
    }

    init(debounceDuration: Double = Constants.fieldDebounceDuration,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onExistingEmail: @escaping ((_ email: String) async -> Void),
         completionHandler: @escaping (() -> Void)) {
        self.stores = stores
        self.analytics = analytics
        self.onExistingEmail = onExistingEmail
        self.completionHandler = completionHandler

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
    func createAccount() async {
        analytics.track(event: .StoreCreation.signupSubmitted())
        isPerformingTask = true

        do {
            let data = try await withCheckedThrowingContinuation { continuation in
                let action = AccountCreationAction.createAccount(email: email, password: password) { result in
                    continuation.resume(with: result)
                }
                stores.dispatch(action)
            }

            analytics.track(event: .StoreCreation.signupSuccess())

            await handleSuccess(data: data)
            completionHandler()

        } catch let error as CreateAccountError {
            /// Skip tracking if the password field is yet to be presented.
            let shouldSkipTrackingError: Bool = {
                guard case .invalidPassword = error else {
                    return false
                }
                return currentField == .email
            }()
            if !shouldSkipTrackingError {
                analytics.track(event: .StoreCreation.signupFailed(error: error))
            }
            await handleFailure(error: error)
        } catch {
            DDLogError("⛔️ Uncaught error when creating WPCom account: \(error)")
        }

        isPerformingTask = false
    }

    func transitionToPasswordField() {
        currentField = .password
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
            await onExistingEmail(email)
        case .invalidEmail:
            emailErrorMessage = Localization.invalidEmailError
        case .invalidPassword(let message):
            if currentField == .email {
                shouldTransitionToPasswordField = true
            } else {
                passwordErrorMessage = message ?? Localization.passwordError
            }
        default:
            break
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
