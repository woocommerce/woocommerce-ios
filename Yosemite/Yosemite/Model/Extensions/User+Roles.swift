import Foundation

/// Convenient extension methods for User model to support role eligibility feature.
extension User {
    /// Convenience method to produce display text representing the user, for the role error page.
    /// This follows the implementation in Android side: fullName > username > email. See: https://git.io/JcJx3
    public func displayName() -> String {
        let fullName = "\(firstName) \(lastName)"
        return [fullName, username].first { !$0.isEmpty } ?? email
    }

    /// Checks whether the user's roles are eligible to access the store.
    public func hasEligibleRoles() -> Bool {
        roles.firstIndex { EligibleRole.allRoles.contains($0.lowercased()) } != nil
    }
}

// MARK: - Private Helpers

private extension User {
    enum EligibleRole: String, CaseIterable {
        case administrator
        case shopManager = "shop_manager"

        /// Convenience method that returns the collection in raw value instead of in enum type.
        static var allRoles: [String] {
            allCases.map { $0.rawValue }
        }
    }
}
