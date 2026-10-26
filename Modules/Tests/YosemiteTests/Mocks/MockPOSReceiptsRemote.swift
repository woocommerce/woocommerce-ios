import Networking
import Synchronization

@dynamicMemberLookup
final class MockPOSReceiptsRemote: POSReceiptsRemoteProtocol {
    struct State {
        var sendReceiptCalled = false
        var sendPOSReceiptCalled = false
        var spySiteID: Int64?
        var spyOrderID: Int64?
        var spyEmail: String?
        var spyTemplateID: String?
        var shouldThrowError: Error?
    }

    private let state = Mutex(State())

    subscript<T: Sendable>(dynamicMember keyPath: WritableKeyPath<State, T>) -> T {
        get { state.withLock { $0[keyPath: keyPath] } }
        set { state.withLock { $0[keyPath: keyPath] = newValue } }
    }

    func sendReceipt(siteID: Int64, orderID: Int64) async throws {
        let shouldThrowError = state.withLock {
            $0.sendReceiptCalled = true
            $0.spySiteID = siteID
            $0.spyOrderID = orderID
            return $0.shouldThrowError
        }

        if let shouldThrowError {
            throw shouldThrowError
        }
    }

    func sendPOSReceipt(siteID: Int64, orderID: Int64, emailAddress: String, templateID: String?) async throws {
        let shouldThrowError = state.withLock {
            $0.sendPOSReceiptCalled = true
            $0.spySiteID = siteID
            $0.spyOrderID = orderID
            $0.spyEmail = emailAddress
            $0.spyTemplateID = templateID
            return $0.shouldThrowError
        }

        if let shouldThrowError {
            throw shouldThrowError
        }
    }
}
