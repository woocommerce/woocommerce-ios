import Foundation
import WordPressShared

/// View model for `CouponAllowedEmails` view.
///
final class CouponAllowedEmailsViewModel: ObservableObject {

    @Published var emailPatterns: String
    @Published var foundInvalidPatterns: Bool = false

    private let onCompletion: (String) -> Void

    init(allowedEmails: String, onCompletion: @escaping (String) -> Void) {
        self.emailPatterns = allowedEmails
        self.onCompletion = onCompletion
    }

    /// Validate the input
    ///
    func validateEmails(dismissHandler: @escaping () -> Void) {
        let emails = emailPatterns.components(separatedBy: ", ")
        foundInvalidPatterns = emails.contains(where: { !EmailFormatValidator.validate(string: $0) })
        if !foundInvalidPatterns {
            onCompletion(emailPatterns)
            dismissHandler()
        }
    }
}
