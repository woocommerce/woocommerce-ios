import Foundation

/// Result of checking a POS permission.
public enum POSPermissionResult: Equatable, Sendable {
    /// The current operator has this capability.
    case allowed
    /// The current operator lacks this capability - manager override can authorize.
    case requiresOverride
}
