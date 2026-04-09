import Foundation

/// Represents the currently active POS operator (the person using the register).
public struct POSOperator: Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let capabilities: Set<String>
    /// True if this operator is the WP-authenticated app account holder.
    public let isAppAccountHolder: Bool

    public init(userID: Int64, displayName: String, role: String,
                capabilities: Set<String>, isAppAccountHolder: Bool) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.capabilities = capabilities
        self.isAppAccountHolder = isAppAccountHolder
    }

    public func hasCapability(_ capability: String) -> Bool {
        capabilities.contains(capability)
    }

    public var initials: String {
        let components = displayName.split(separator: " ")
        switch components.count {
        case 0: return "?"
        case 1: return String(components[0].prefix(1)).uppercased()
        default:
            let first = components[0].prefix(1)
            let last = components[components.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
    }
}
