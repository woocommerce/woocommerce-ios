import Yosemite

/// Encapsulates Storage.EligibilityErrorInfo interface helpers.
///
extension StorageEligibilityErrorInfo {
    /// Convenience method that converts the roles to a display-friendly format.
    /// e.g. ["author", "shop_manager"] -> "Author, Shop Manager"
    var humanizedRoles: String {
        roles.map { User.Role.displayText(for: $0) }.joined(separator: ", ")
    }
}
