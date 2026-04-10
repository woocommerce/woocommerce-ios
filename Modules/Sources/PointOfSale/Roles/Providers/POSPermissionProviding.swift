import Foundation

/// Shared protocol for POS permission checking.
/// Two implementations: LocalPOSPermissionProvider, RemotePOSPermissionProvider.
/// All POS views use this protocol via @Environment(\.posPermissions).
public protocol POSPermissionProviding: AnyObject {
    var currentOperator: POSOperator? { get }
    var isLocked: Bool { get }
    func checkPermission(_ capability: String) -> POSPermissionResult
    func hasCapability(_ capability: String) -> Bool
    func signIn(_ posOperator: POSOperator)
    func lock()
    func resetInactivityTimer()
    var autoLockTimeoutSeconds: Int { get }
}

// MARK: - POSCapability convenience

extension POSPermissionProviding {
    /// Check permission using the typed capability enum.
    /// Usage: `permissions.checkPermission(.refundOrders)`
    func checkPermission(_ capability: POSCapability) -> POSPermissionResult {
        checkPermission(capability.rawValue)
    }

    /// Check if the current operator has the typed capability.
    /// Usage: `permissions.hasCapability(.applyDiscounts)`
    func hasCapability(_ capability: POSCapability) -> Bool {
        hasCapability(capability.rawValue)
    }
}
