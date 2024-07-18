import Foundation

/// Convenient extension methods for User model to support role eligibility feature.
extension User {
    /// Convenience method to produce display text representing the user, for the role error page.
    /// This follows the implementation in Android side: fullName > username > email. See: https://git.io/JcJx3
    public func displayName() -> String {
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return [fullName, username].first { !$0.isEmpty } ?? email
    }

    /// Checks whether the user's roles are eligible to access the store.
    public func hasEligibleRoles() -> Bool {
        roles.compactMap { Role(rawValue: $0) }.firstIndex { $0.isEligible() } != nil
    }
}


// MARK: - Roles

extension User {
    /// Encapsulates all the default roles defined in WooCommerce sites.
    ///
    public enum Role: String {
        case administrator
        case author
        case contributor
        case customer
        case editor
        case shopManager = "shop_manager"
        case subscriber

        /// Returns a user-friendly format of the role to be displayed on screen.
        ///
        public func displayString() -> String {
            switch self {
            case .administrator:
                return NSLocalizedString("Administrator", comment: "User's Administrator role.")
            case .author:
                return NSLocalizedString("Author", comment: "User's Author role.")
            case .contributor:
                return NSLocalizedString("Contributor", comment: "User's Contributor role.")
            case .customer:
                return NSLocalizedString("Customer", comment: "User's Customer role.")
            case .editor:
                return NSLocalizedString("Editor", comment: "User's Editor role.")
            case .shopManager:
                return NSLocalizedString("Shop Manager", comment: "User's Shop Manager role.")
            case .subscriber:
                return NSLocalizedString("Subscriber", comment: "User's Subscriber role.")
            }
        }

        /// Checks if the role is eligible to manage the store. Returns true if the role is eligible.
        ///
        public func isEligible() -> Bool {
            return Constants.eligibleRoles.contains(self)
        }

        /// Convenience static method that converts role string value into a user-friendly format.
        /// This also handles the case where the roleString is non-default or not recognized, in which
        /// we will return a titlecased version of the role instead.
        ///
        /// - Parameter roleString: The string value of the role.
        /// - Returns: The role formatted for display.
        ///
        public static func displayText(for roleString: String) -> String {
            guard let role = Role(rawValue: roleString) else {
                return roleString.titleCasedFromSnakeCase
            }

            return role.displayString()
        }
    }
}

// MARK: - Private Helpers

private extension User {
    struct Constants {
        /// A list of roles that are eligible to access the store through the WooCommerce app.
        static let eligibleRoles: [Role] = [.administrator, .shopManager]
    }
}

private extension String {
    /// Convenience function that converts snake-cased strings into title case.
    /// e.g. "shop_manager" -> "Shop Manager"
    var titleCasedFromSnakeCase: String {
        guard contains("_") else {
            return capitalized
        }
        return components(separatedBy: "_").map { $0.capitalized }.joined(separator: " ")
    }
}
