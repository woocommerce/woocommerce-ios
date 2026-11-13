import Dispatch
@testable import PointOfSale

final class MockBlockingPOSPINStore: POSPINManaging, Sendable {
    private let store: POSLocalPINStore
    private let fails: Bool
    private let blocksValidation: Bool
    private let entered = DispatchSemaphore(value: 0)
    private let release = DispatchSemaphore(value: 0)

    init(store: POSLocalPINStore, fails: Bool = false, blocksValidation: Bool = false) {
        self.store = store
        self.fails = fails
        self.blocksValidation = blocksValidation
    }

    func configuredRoles() throws(POSPINStoreError) -> Set<POSLocalRole> { try store.configuredRoles() }

    func validatePIN(_ pin: String, for role: POSLocalRole) throws(POSPINStoreError) {
        if blocksValidation { try waitForRelease() }
        try store.validatePIN(pin, for: role)
    }

    func setPIN(_ pin: String, for role: POSLocalRole) throws(POSPINStoreError) {
        try waitForRelease()
        try store.setPIN(pin, for: role)
    }

    func removePIN(for role: POSLocalRole) throws(POSPINStoreError) {
        try waitForRelease()
        try store.removePIN(for: role)
    }

    func waitUntilEntered() async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async { [entered] in
                guard entered.wait(timeout: .now() + 2) == .success else {
                    continuation.resume(throwing: Failure.mutationDidNotStart)
                    return
                }
                continuation.resume()
            }
        }
    }

    private enum Failure: Error { case mutationDidNotStart }

    func releaseMutation() { release.signal() }

    private func waitForRelease() throws(POSPINStoreError) {
        entered.signal()
        guard release.wait(timeout: .now() + 5) == .success, !fails else { throw .storageFailure }
    }
}
