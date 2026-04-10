@testable import PointOfSale

final class MockPOSPermissionProvider: POSPermissionProviding {
    var currentOperator: POSOperator?
    var isLocked: Bool = false
    var autoLockTimeoutSeconds: Int = 300
    var capabilityOverrides: [String: POSPermissionResult] = [:]
    var resetInactivityTimerCallCount: Int = 0
    var requestedManagerPIN: String?
    var requestedCapability: String?
    var requestedOrderID: Int64?
    var approvalTokenToReturn: String?
    var approvalErrorToThrow: Error?

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

    func requestManagerApproval(managerPIN: String, for capability: String, orderID: Int64?) async throws -> String? {
        requestedManagerPIN = managerPIN
        requestedCapability = capability
        requestedOrderID = orderID

        if let approvalErrorToThrow {
            throw approvalErrorToThrow
        }

        return approvalTokenToReturn
    }

    func signIn(_ posOperator: POSOperator) {
        currentOperator = posOperator
        isLocked = false
    }

    func lock() {
        currentOperator = nil
        isLocked = true
    }

    func resetInactivityTimer() {
        resetInactivityTimerCallCount += 1
    }
}
