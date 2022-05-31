import Foundation

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
    func validateEmails() -> Bool {
        // TODO: implement this
        return true
    }
}
