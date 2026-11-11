@testable import PointOfSale

final class MockPOSPINCredentialProvider: POSPINCredentialProviding, @unchecked Sendable {
    var credentialsResult: Result<[POSPINCredential], POSPINStoreError>

    init(credentialsResult: Result<[POSPINCredential], POSPINStoreError> = .success([])) {
        self.credentialsResult = credentialsResult
    }

    func credentials() throws(POSPINStoreError) -> [POSPINCredential] {
        try credentialsResult.get()
    }
}
