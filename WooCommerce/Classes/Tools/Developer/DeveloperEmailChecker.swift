import Foundation

struct DeveloperEmailChecker {
    private let developerEmails = ["@automattic.com", "@a8c.com"]

    /// Checks if an email belongs to app developer (Automattic).
    ///
    func isDeveloperEmail(email: String) -> Bool {
        return (developerEmails.first { email.contains($0) }) != nil
    }
}
