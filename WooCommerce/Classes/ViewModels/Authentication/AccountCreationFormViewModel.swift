import Combine
import Foundation
import struct Yosemite.CreateAccountResult
import struct Yosemite.Credentials
import enum Yosemite.AccountAction
import enum Yosemite.AccountCreationAction
import enum Yosemite.CreateAccountError
import protocol Yosemite.StoresManager
import class WordPressShared.EmailFormatValidator

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
    private var subscriptions: Set<AnyCancellable> = []

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores

        $email
            .removeDuplicates()
            .debounce(for: .seconds(Constants.fieldDebounceDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }.store(in: &subscriptions)

        $password
            .removeDuplicates()
            .debounce(for: .seconds(Constants.fieldDebounceDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] password in
                self?.validatePassword(password)
            }.store(in: &subscriptions)
    }

    /// Creates a WPCOM account with the email and password.
    /// - Returns: async result of account creation.
    @MainActor
    func createAccount() async -> Result<Void, Error> {
        let result: Result<CreateAccountResult, CreateAccountError> = await withCheckedContinuation { continuation in
            let action = AccountCreationAction.createAccount(email: email, password: password) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }

        switch result {
        case .success(let data):
            await handleSuccess(data: data)
            return .success(())
        case .failure(let error):
            handleFailure(error: error)
            return .failure(error)
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
    func handleFailure(error: CreateAccountError) {
        switch error {
        case .emailExists:
            emailErrorMessage = Localization.emailExistsError
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
        static let emailExistsError = NSLocalizedString("An account with this email already exists.",
                                                        comment: "Account creation error when the email is already associated with an existing WP.com account.")
        static let invalidEmailError = NSLocalizedString("Use a working email address, so you can receive our messages.",
                                                         comment: "Account creation error when the email is invalid.")
        static let passwordError = NSLocalizedString("Password must be at least 6 characters.",
                                                     comment: "Account creation error when the password is invalid.")
        static let otherError = NSLocalizedString("Please try again.",
                                                  comment: "Account creation error when an unexpected error occurs.")
    }
}
