@testable import PointOfSale

final class MockPOSPermissionProvider: POSPermissionProviding {
    var currentOperator: POSOperator?
    var isLocked: Bool = false
    var capabilityOverrides: [String: POSPermissionResult] = [:]

    func checkPermission(_ capability: String) -> POSPermissionResult {
        if let override = capabilityOverrides[capability] {
            return override
        }
        guard let op = currentOperator else {
            return .requiresOverride
        }
        return op.hasCapability(capability) ? .allowed : .requiresOverride
    }

    func hasCapability(_ capability: String) -> Bool {
        checkPermission(capability) == .allowed
    }

    func signIn(_ posOperator: POSOperator) {
        currentOperator = posOperator
        isLocked = false
    }

    func lock() {
        currentOperator = nil
        isLocked = true
    }
}
