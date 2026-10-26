import Foundation
import Synchronization
@testable import Yosemite

@dynamicMemberLookup
final class MockReceiptService: POSReceiptServiceProtocol {
    struct State {
        var sendReceiptWasCalled: Bool?
        var spyIsEligibleForPOSReceipt: Bool?
        var spyTemplateID: String?
        var sendReceiptResult: Result<Void, Error> = .success(())
    }

    private let state = Mutex(State())

    subscript<T: Sendable>(dynamicMember keyPath: WritableKeyPath<State, T>) -> T {
        get { state.withLock { $0[keyPath: keyPath] } }
        set { state.withLock { $0[keyPath: keyPath] = newValue } }
    }

    func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool, templateID: String?) async throws {
        let result = state.withLock {
            $0.sendReceiptWasCalled = true
            $0.spyIsEligibleForPOSReceipt = isEligibleForPOSReceipt
            $0.spyTemplateID = templateID
            return $0.sendReceiptResult
        }
        try result.get()
    }
}
