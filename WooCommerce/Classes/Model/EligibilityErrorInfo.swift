import Foundation

/// Convenience type that encapsulates display information for user ineligible for managing the store.
struct EligibilityErrorInfo {
    /// the name of the ineligible user, for display purposes.
    let name: String

    /// The roles of the ineligible user, for display purposes.
    let roles: [String]

    /// Convenience method that converts the roles to a display-friendly format.
    /// e.g. ["author", "shop_manager"] -> "Author, Shop Manager"
    var humanizedRoles: String {
        roles.map { $0.titleCasedFromSnakeCase }.joined(separator: ", ")
    }

    init(name: String, roles: [String]) {
        self.name = name
        self.roles = roles
    }

    /// Converts dictionary into EligibilityErrorInfo.
    /// Note that the value for `roles` needs to be in a specific format. See: `toDictionary()`.
    init?(from dictionary: [String: String]) {
        guard let name = dictionary[Constants.nameKey],
              let roles = dictionary[Constants.rolesKey] else {
            return nil
        }

        self.init(name: name, roles: roles.components(separatedBy: Constants.separatorString))
    }

    /// Formats the struct to a simple string dictionary structure.
    /// Roles will be serialized by turning them into a single string with comma-separated values.
    func toDictionary() -> [String: String] {
        return [
            Constants.nameKey: name,
            Constants.rolesKey: roles.joined(separator: Constants.separatorString)
        ]
    }
}

// MARK: - Private Helpers

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

private extension EligibilityErrorInfo {
    enum Constants {
        static let nameKey = "name"
        static let rolesKey = "roles"
        static let separatorString = ","
    }
}
