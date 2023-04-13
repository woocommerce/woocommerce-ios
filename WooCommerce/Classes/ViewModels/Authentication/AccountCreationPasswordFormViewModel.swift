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
final class AccountCreationPasswordFormViewModel: ObservableObject {

    /// Password input.
    @Published var password: String = ""
    /// An error can come from the WPCOM backend, when the password is too simple.
    @Published private(set) var passwordErrorMessage: String?
    /// Local validation on the password field.
    @Published private(set) var isPasswordValid: Bool = false

    /// Email input.
    private let email: String
    private let stores: StoresManager
    private let analytics: Analytics
    private var subscriptions: Set<AnyCancellable> = []

    init(email: String,
         debounceDuration: Double = Constants.fieldDebounceDuration,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.email = email
        self.stores = stores
        self.analytics = analytics

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
            analytics.track(event: .StoreCreation.signupFailed(error: error))
            handleFailure(error: error)
            throw error
        }
    }
}

private extension AccountCreationPasswordFormViewModel {

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
        case .invalidPassword(let message):
            passwordErrorMessage = message ?? Localization.passwordError

        default:
            break
        }
    }
}

private extension AccountCreationPasswordFormViewModel {
    func validatePassword(_ password: String) {
        isPasswordValid = password.count >= 6
        passwordErrorMessage = nil
    }
}

private extension AccountCreationPasswordFormViewModel {
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
