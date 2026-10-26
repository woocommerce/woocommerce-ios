import Foundation
import Synchronization
import Yosemite
import enum WooFoundation.CurrencyCode

/// Mock for `POSOrderServiceProtocol` in app-target tests. Only `loadOrder` is stubbed with a
/// meaningful value; the remaining methods are unused by the current tests and fail loudly if reached.
final class MockPOSOrderService: POSOrderServiceProtocol {
    private struct State {
        var orderToReturn: Order?
        var spyLoadOrderID: Int64?
    }

    private let state = Mutex(State())

    var orderToReturn: Order? {
        get { state.withLock { $0.orderToReturn } }
        set { state.withLock { $0.orderToReturn = newValue } }
    }

    var spyLoadOrderID: Int64? {
        state.withLock { $0.spyLoadOrderID }
    }

    func loadOrder(orderID: Int64) async throws -> Order {
        let orderToReturn = state.withLock {
            $0.spyLoadOrderID = orderID
            return $0.orderToReturn
        }
        guard let order = orderToReturn else {
            throw MockPOSOrderServiceError.missingStub
        }
        return order
    }

    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order {
        throw MockPOSOrderServiceError.notImplemented
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {
        throw MockPOSOrderServiceError.notImplemented
    }

    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {
        throw MockPOSOrderServiceError.notImplemented
    }

    func markOrderAsCompletedManually(order: Order) async throws {
        throw MockPOSOrderServiceError.notImplemented
    }

    func promoteOrderToPending(order: Order) async throws -> Order {
        throw MockPOSOrderServiceError.notImplemented
    }

    func addOrderNote(orderID: Int64, isCustomerNote: Bool, note: String) async throws {
        throw MockPOSOrderServiceError.notImplemented
    }

    func recordScanToPayPaymentMethod(order: Order) async throws {
        throw MockPOSOrderServiceError.notImplemented
    }
}

enum MockPOSOrderServiceError: Error {
    case missingStub
    case notImplemented
}
