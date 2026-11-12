@testable import PointOfSale

struct MockPOSPINRecovery: POSPINRecoveryAuthenticating {
    let result: Result<POSStaff, POSAuthError>
    func authenticate() async throws(POSAuthError) -> POSStaff { try result.get() }
}
