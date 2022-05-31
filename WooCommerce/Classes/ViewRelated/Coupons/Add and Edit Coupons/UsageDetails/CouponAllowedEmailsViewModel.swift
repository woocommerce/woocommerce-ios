import Foundation

/// View model for `CouponAllowedEmails` view.
///
final class CouponAllowedEmailsViewModel: ObservableObject {

    @Published var allowedEmails: String

    @Published private(set) var foundInvalidPatterns: Bool = false

    init(allowedEmails: String) {
        self.allowedEmails = allowedEmails
    }

    /// Validate the input
    ///
    func validateEmails() {
        
    }
}
