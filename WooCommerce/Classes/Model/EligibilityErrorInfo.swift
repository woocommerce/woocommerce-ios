import Foundation
import Yosemite

/// Convenience type that encapsulates display information for user ineligible for managing the store.
struct EligibilityErrorInfo {
    /// the name of the ineligible user, for display purposes.
    let name: String

    /// The roles of the ineligible user, for display purposes.
    let roles: [String]

    init(name: String, roles: [String]) {
        self.name = name
        self.roles = roles
    }

    init?(from dictionary: [String: String]) {
        guard let name = dictionary[Constants.nameKey],
              let roles = dictionary[Constants.rolesKey] else {
            return nil
        }

        self.init(name: name, roles: roles.components(separatedBy: Constants.separatorString))
    }

    func toDictionary() -> [String: String] {
        return [
            Constants.nameKey: name,
            Constants.rolesKey: roles.joined(separator: Constants.separatorString)
        ]
    }
}

private extension EligibilityErrorInfo {
    enum Constants {
        static let nameKey = "name"
        static let rolesKey = "roles"
        static let separatorString = ","
    }
}
