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

/// Default no-op provider when roles are disabled.
final class EmptyPOSPermissionProvider: POSPermissionProviding {
    var currentOperator: POSOperator? { nil }
    var isLocked: Bool { false }
    func checkPermission(_ capability: String) -> POSPermissionResult { .allowed }
    func hasCapability(_ capability: String) -> Bool { true }
    func signIn(_ posOperator: POSOperator) {}
    func lock() {}
}
