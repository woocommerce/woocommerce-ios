import Foundation

/// Shared protocol for POS permission checking.
/// Two implementations: LocalPOSPermissionProvider, RemotePOSPermissionProvider.
/// All POS views use this protocol via @Environment(\.posPermissions).
public protocol POSPermissionProviding: AnyObject {
    var currentOperator: POSOperator? { get }
    var isLocked: Bool { get }
    func checkPermission(_ capability: String) -> POSPermissionResult
    func hasCapability(_ capability: String) -> Bool
    func requestManagerApproval(managerPIN: String, for capability: String, orderID: Int64?) async throws -> String?
    func signIn(_ posOperator: POSOperator)
    func lock()
    func resetInactivityTimer()
    var autoLockTimeoutSeconds: Int { get }
    /// Whether any PINs are configured (at least one staff member has a PIN).
    /// Used to determine if "Lock POS" should be available.
    var hasAnyPINs: Bool { get }
}

// MARK: - POSCapability convenience

extension POSPermissionProviding {
    /// Check permission using the typed capability enum.
    /// Usage: `permissions.checkPermission(.refundOrders)`
    func checkPermission(_ capability: POSCapability) -> POSPermissionResult {
        checkPermission(capability.rawValue)
    }

    /// Check if the current operator has the typed capability.
    /// Usage: `permissions.hasCapability(.publishCoupons)`
    func hasCapability(_ capability: POSCapability) -> Bool {
        hasCapability(capability.rawValue)
    }

    /// Requests manager approval using the typed capability enum.
    func requestManagerApproval(managerPIN: String,
                                for capability: POSCapability,
                                orderID: Int64? = nil) async throws -> String? {
        try await requestManagerApproval(managerPIN: managerPIN,
                                         for: capability.rawValue,
                                         orderID: orderID)
    }
}
