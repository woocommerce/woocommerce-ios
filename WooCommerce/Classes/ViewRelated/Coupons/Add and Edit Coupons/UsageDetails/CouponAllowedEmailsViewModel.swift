import Foundation
import WordPressShared

/// View model for `CouponAllowedEmails` view.
///
final class CouponAllowedEmailsViewModel: ObservableObject {

    @Published var emailPatterns: String

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

    private let onCompletion: (String) -> Void

    init(allowedEmails: String, onCompletion: @escaping (String) -> Void) {
        self.emailPatterns = allowedEmails
        self.onCompletion = onCompletion
    }

    /// Validate the input
    ///
    func validateEmails(dismissHandler: @escaping () -> Void) {
        let emails = emailPatterns.components(separatedBy: ", ")
        let foundInvalidPatterns = emails.contains(where: { !EmailFormatValidator.validate(string: $0) })
        if emailPatterns.isEmpty || !foundInvalidPatterns {
            onCompletion(emailPatterns)
            dismissHandler()
        } else {
            notice = Notice(title: Localization.failedEmailValidation, feedbackType: .error)
        }
    }
}

private extension CouponAllowedEmailsViewModel {
    enum Localization {
        static let failedEmailValidation = NSLocalizedString(
            "Some email address is not valid.",
            comment: "Error message when at least an address on the Coupon Allowed Emails screen is not valid."
        )
    }
}
