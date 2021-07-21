/// Convenience type that encapsulates display information of an error, describing
/// that the user does not have the correct role to access the selected store.
///
/// This information is persisted in a plist file, as part of `GeneralAppSettings`.
///
public struct EligibilityErrorInfo: Codable, Equatable {
    /// the name of the ineligible user, for display purposes.
    public let name: String

    /// The roles of the ineligible user, for display purposes.
    public let roles: [String]

    public init(name: String, roles: [String]) {
        self.name = name
        self.roles = roles
    }
}
