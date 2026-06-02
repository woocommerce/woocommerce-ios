import Foundation
@testable import PointOfSale

@MainActor
final class MockPOSPINAuthenticator: POSPINAuthenticating {
    var authenticateResult: Result<POSStaff, POSAuthError>
    var verifyResult: Result<POSStaff, POSAuthError>

    private(set) var authenticatedPINs: [String] = []
    private(set) var verifyCallCount: Int = 0

    init(authenticateResult: Result<POSStaff, POSAuthError> = .success(
            POSStaff(
                userID: 1,
                displayName: "Maya",
                role: "shop_manager",
                capabilities: Set(POSCapability.allCases.map(\.rawValue))
            )
         ),
         verifyResult: Result<POSStaff, POSAuthError> = .success(
            POSStaff(
                userID: 2,
                displayName: "Morgan",
                role: "shop_manager",
                capabilities: Set(POSCapability.allCases.map(\.rawValue))
            )
         )) {
        self.authenticateResult = authenticateResult
        self.verifyResult = verifyResult
    }

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        authenticatedPINs.append(pin)
        return try authenticateResult.get()
    }

    func verify(managerPIN pin: String, authorizes capability: POSCapability)
        async throws(POSAuthError) -> POSStaff {
        verifyCallCount += 1
        return try verifyResult.get()
    }
}
