import SwiftUI

struct POSPermissionsKey: EnvironmentKey {
    static let defaultValue: POSPermissionProviding = EmptyPOSPermissionProvider()
}

extension EnvironmentValues {
    var posPermissions: POSPermissionProviding {
        get { self[POSPermissionsKey.self] }
        set { self[POSPermissionsKey.self] = newValue }
    }
}

/// Default no-op provider used in previews and when roles are disabled.
final class EmptyPOSPermissionProvider: POSPermissionProviding {
    var currentOperator: POSOperator? { nil }
    var isLocked: Bool { false }
    var hasAnyPINs: Bool { false }
    var autoLockTimeoutSeconds: Int { 0 }
    func hasCapability(_ capability: String) -> Bool { true }
    func checkPermission(_ capability: String) -> POSPermissionResult { .allowed }
    func requestManagerApproval(managerPIN: String, for capability: String) async throws -> POSOperator {
        POSOperator(userID: 0, displayName: "", role: "", capabilities: [], isAppAccountHolder: false)
    }
    func signIn(_ posOperator: POSOperator) {}
    func lock() {}
    func resetInactivityTimer() {}
}
