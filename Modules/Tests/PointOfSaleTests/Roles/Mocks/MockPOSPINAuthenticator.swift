import Foundation
@testable import PointOfSale

@MainActor
final class MockPOSPINAuthenticator: POSPINAuthenticating {
    var authenticateResult: Result<POSStaff, POSAuthError>
    var verifyResult: Result<POSStaff, POSAuthError>

    /// When non-empty, the first element is dequeued on each `authenticate` call and used instead of
    /// `authenticateResult`. Lets a test drive the session's refresh-on-miss retry: e.g. `.failure(.invalidPIN)`
    /// then `.success(staff)`. Once exhausted, `authenticateResult` takes over.
    var authenticateResultSequence: [Result<POSStaff, POSAuthError>] = []

    /// Same as `authenticateResultSequence`, but for `verify`.
    var verifyResultSequence: [Result<POSStaff, POSAuthError>] = []

    private(set) var authenticatedPINs: [String] = []
    private(set) var verifyCallCount: Int = 0

    init(authenticateResult: Result<POSStaff, POSAuthError> = .success(
            POSStaff(
                userID: 1,
                displayName: "Maya",
                preset: "pos_manager",
                capabilities: Set(POSCapability.allCases.map(\.rawValue))
            )
         ),
         verifyResult: Result<POSStaff, POSAuthError> = .success(
            POSStaff(
                userID: 2,
                displayName: "Morgan",
                preset: "pos_manager",
                capabilities: Set(POSCapability.allCases.map(\.rawValue))
            )
         )) {
        self.authenticateResult = authenticateResult
        self.verifyResult = verifyResult
    }

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        authenticatedPINs.append(pin)
        let result = authenticateResultSequence.isEmpty ? authenticateResult : authenticateResultSequence.removeFirst()
        return try result.get()
    }

    func verify(managerPIN pin: String, authorizes capability: POSCapability) async throws(POSAuthError) -> POSStaff {
        verifyCallCount += 1
        let result = verifyResultSequence.isEmpty ? verifyResult : verifyResultSequence.removeFirst()
        return try result.get()
    }
}
