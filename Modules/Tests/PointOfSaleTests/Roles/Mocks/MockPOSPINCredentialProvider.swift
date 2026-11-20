import Synchronization
@testable import PointOfSale

final class MockPOSPINCredentialProvider: POSPINCredentialProviding, Sendable {
    private let result: Mutex<Result<[POSPINCredential], POSPINStoreError>>

    init(credentialsResult: Result<[POSPINCredential], POSPINStoreError> = .success([])) {
        self.result = Mutex(credentialsResult)
    }

    var credentialsResult: Result<[POSPINCredential], POSPINStoreError> {
        get { result.withLock { $0 } }
        set { result.withLock { $0 = newValue } }
    }

    func credentials() throws(POSPINStoreError) -> [POSPINCredential] {
        try result.withLock { $0 }.get()
    }
}
