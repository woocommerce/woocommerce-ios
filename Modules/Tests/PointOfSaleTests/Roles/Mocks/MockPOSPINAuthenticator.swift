import Foundation
@testable import PointOfSale

@MainActor
final class MockPOSPINAuthenticator: POSPINAuthenticating {
    var authenticateResult: Result<POSStaff, POSAuthError>
    var verifyResult: Result<Void, POSAuthError>
    var hasAnyPINsResult: Result<Bool, POSAuthError>

    private(set) var authenticatedPINs: [String] = []
    private(set) var verifyCallCount: Int = 0
    private(set) var hasAnyPINsCallCount: Int = 0

    init(authenticateResult: Result<POSStaff, POSAuthError> = .success(
            POSStaff(
                displayName: "Maya",
                role: "shop_manager",
                capabilities: Set(POSCapability.allCases.map(\.rawValue))
            )
         ),
         verifyResult: Result<Void, POSAuthError> = .success(()),
         hasAnyPINsResult: Result<Bool, POSAuthError> = .success(true)) {
        self.authenticateResult = authenticateResult
        self.verifyResult = verifyResult
        self.hasAnyPINsResult = hasAnyPINsResult
    }

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        authenticatedPINs.append(pin)
        return try authenticateResult.get()
    }

    func verify(managerPIN pin: String, authorizes capability: POSCapability)
        async throws(POSAuthError) {
        verifyCallCount += 1
        _ = try verifyResult.get()
    }

    func hasAnyPINs() async throws(POSAuthError) -> Bool {
        hasAnyPINsCallCount += 1
        return try hasAnyPINsResult.get()
    }
}
