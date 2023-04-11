import Combine
import Foundation
import struct Yosemite.CreateAccountResult
import enum Yosemite.Credentials
import enum Yosemite.AccountAction
import enum Yosemite.AccountCreationAction
import enum Yosemite.CreateAccountError
import protocol Yosemite.StoresManager
import class WordPressShared.EmailFormatValidator
import class WordPressAuthenticator.WordPressComAccountService

/// View model for `AccountCreationForm` view.
final class AccountCreationFormViewModel: ObservableObject {
    /// Email input.
    @Published var email: String = ""
    /// An error can come from the WPCOM backend, when the email is invalid or already exists.
    @Published private(set) var emailErrorMessage: String?
    /// Local validation on the email field.
    @Published private var isEmailValid: Bool = false

    /// Password input.
    @Published var password: String = ""
    /// An error can come from the WPCOM backend, when the password is too simple.
    @Published private(set) var passwordErrorMessage: String?
    /// Local validation on the password field.
    @Published private var isPasswordValid: Bool = false

    /// Whether the password field should be present.
    @Published private(set) var shouldShowPasswordField: Bool = false

    @Published private(set) var submitButtonEnabled: Bool = false

    /// Whether the user attempts to sign up with an email that is associated with an existing WPCom account.
    @Published private(set) var existingEmailFound: Bool = false

    private let stores: StoresManager
    private let analytics: Analytics
    private var subscriptions: Set<AnyCancellable> = []
    private let accountService: WordPressComAccountServiceProtocol

    init(debounceDuration: Double = Constants.fieldDebounceDuration,
         stores: StoresManager = ServiceLocator.stores,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.analytics = analytics
        self.accountService = accountService

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

        $shouldShowPasswordField
            .combineLatest($isEmailValid, $isPasswordValid)
            .map { (shouldShowPasswordField, isEmailValid, isPasswordValid) -> Bool in
                guard shouldShowPasswordField else {
                    return isEmailValid
                }
                return isEmailValid && isPasswordValid
            }
            .assign(to: &$submitButtonEnabled)
    }

    /// Checks the entered email if it is associated with an existing WPCom account.
    /// If not, creates a WPCOM account with the email and password.
    /// - Returns: whether the creation succeeds.
    @MainActor
    func createAccountIfPossible() async -> Bool {
        guard shouldShowPasswordField else {
            existingEmailFound = await checkIfWordPressAccountExists()
            shouldShowPasswordField = !existingEmailFound
            return false
        }
        let createAccountCompleted = (try? await createAccount()) != nil
        return createAccountCompleted
    }
}

private extension AccountCreationFormViewModel {
    @MainActor
    func checkIfWordPressAccountExists() async -> Bool {
        do {
            let accountExists: Bool = try await withCheckedThrowingContinuation { continuation in
                accountService.isPasswordlessAccount(username: email, success: { _ in
                    continuation.resume(returning: true)
                }, failure: { error in
                    DDLogError("⛔️ Error checking for passwordless account: \(error)")
                    continuation.resume(throwing: error)
                })
            }
            return accountExists
        } catch {
            return false
        }
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
            analytics.track(event: .StoreCreation.signupFailed(error: error))
            handleFailure(error: error)
            throw error
        }
    }

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
    func handleFailure(error: CreateAccountError) {
        switch error {
        case .emailExists:
            existingEmailFound = true
        case .invalidEmail:
            emailErrorMessage = Localization.invalidEmailError
        case .invalidPassword(let message):
            passwordErrorMessage = message ?? Localization.passwordError
        default:
            break
        }
    }
}

private extension AccountCreationFormViewModel {
    func validateEmail(_ email: String) {
        isEmailValid = EmailFormatValidator.validate(string: email)
        existingEmailFound = false
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
