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
}
