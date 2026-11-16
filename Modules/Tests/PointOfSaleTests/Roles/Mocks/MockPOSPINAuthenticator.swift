import Foundation
@testable import PointOfSale

@MainActor
final class MockPOSPINAuthenticator: POSPINAuthenticating {
    var authenticateResult: Result<POSStaff, POSAuthError>
    var onAuthenticate: (@MainActor () async -> Void)?

    private(set) var authenticatedPINs: [String] = []

    init(authenticateResult: Result<POSStaff, POSAuthError> = .success(POSLocalRole.admin.staff)) {
        self.authenticateResult = authenticateResult
    }

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        authenticatedPINs.append(pin)
        await onAuthenticate?()
        return try authenticateResult.get()
    }
}
