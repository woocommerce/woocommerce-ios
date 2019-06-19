import Foundation

struct DeveloperEmailChecker {
    private static let developerEmails = ["@automattic.com", "@a8c.com"]

    /// Checks if an email belongs to app developer (Automattic).
    ///
    static func isDeveloperEmail(email: String) -> Bool {
        return (developerEmails.first { email.contains($0) }) != nil
    }
}
