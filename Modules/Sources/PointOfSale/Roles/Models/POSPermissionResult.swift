import Foundation

/// Result of checking a POS permission.
public enum POSPermissionResult: Equatable, Sendable {
    /// The current operator has this capability.
    case allowed
    /// The current operator lacks this capability — a higher-role staff member can
    /// authorize the action by re-entering their PIN (M1 manager-override flow).
    case requiresOverride
}
