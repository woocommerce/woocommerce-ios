import Combine
import Foundation
import class WordPressShared.EmailFormatValidator
import class WordPressAuthenticator.WordPressComAccountService

/// View model for `AccountCreationForm` view.
final class AccountCreationEmailFormViewModel: ObservableObject {
    /// Email input.
    @Published var email: String = ""
    /// An error can come from the WPCOM backend, when the email is invalid or already exists.
    @Published private(set) var emailErrorMessage: String?
    /// Local validation on the email field.
    @Published private(set) var isEmailValid: Bool = false

    private let accountService: WordPressComAccountServiceProtocol
    private let analytics: Analytics
    private var subscriptions: Set<AnyCancellable> = []

    init(debounceDuration: Double = Constants.fieldDebounceDuration,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         analytics: Analytics = ServiceLocator.analytics) {
        self.accountService = accountService
        self.analytics = analytics

        $email
            .removeDuplicates()
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }.store(in: &subscriptions)
    }

    @MainActor
    func checkIfWPComAccountExists() async -> Bool {
        await withCheckedContinuation { continuation in
            accountService.isPasswordlessAccount(username: email) { _ in
                continuation.resume(returning: true)
            } failure: { error in
                let userInfo = (error as NSError).userInfo
                if userInfo[Constants.errorCodeKey] as? String == Constants.emailLoginNotAllowedCode {
                    /// If the user gets `email_login_not_allowed` error, an account with this email exists.
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

private extension AccountCreationEmailFormViewModel {
    func validateEmail(_ email: String) {
        isEmailValid = EmailFormatValidator.validate(string: email)
        emailErrorMessage = nil
    }
}

private extension AccountCreationEmailFormViewModel {
    enum Constants {
        static let fieldDebounceDuration = 0.3
        static let errorCodeKey = "WordPressComRestApiErrorCodeKey"
        static let emailLoginNotAllowedCode = "email_login_not_allowed"
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
