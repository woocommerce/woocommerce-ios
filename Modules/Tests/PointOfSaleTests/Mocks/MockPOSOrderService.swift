import Foundation
import Synchronization
@testable import Yosemite
import WooFoundation

@dynamicMemberLookup
final class MockPOSOrderService: POSOrderServiceProtocol {
    struct State {
        var simulateSyncing = false
        var orderToReturn: Order?
        var errorToReturn: Error?
        // This does not replace the previous `errorToReturn`/`orderToReturn` only to keep the changes small.
        var resultToReturn: Result<Void, Error> = .success(())

        var syncOrderWasCalled = false
        var syncOrderCallCount = 0
        var updateOrderWasCalled = false
        var spySyncOrderCurrency: CurrencyCode?
        var spyCashPaymentChangeDueAmount: String?

        var onSyncOrderCalled: (@MainActor @Sendable () async -> Void)?
        var onLoadOrderCalled: (@MainActor @Sendable () async -> Void)?
        var onPromoteOrderCalled: (@MainActor @Sendable () async -> Void)?

        var loadOrderWasCalled = false

        var markOrderAsCompletedManuallyWasCalled = false
        var spyMarkOrderAsCompletedManuallyOrder: Order?

        var promoteOrderToPendingWasCalled = false
        var spyPromoteOrderToPendingOrder: Order?
        var promoteOrderToPendingOverride: Order?

        var addOrderNoteWasCalled = false
        var spyAddOrderNoteOrderID: Int64?
        var spyAddOrderNoteIsCustomerNote: Bool?
        var spyAddOrderNoteText: String?
        /// When non-nil, overrides `resultToReturn` for `addOrderNote` calls only.
        var addOrderNoteResult: Result<Void, Error>?

        var recordScanToPayPaymentMethodWasCalled = false
        var spyRecordScanToPayPaymentMethodOrder: Order?
        var recordScanToPayPaymentMethodResult: Result<Void, Error>?
    }

    private let state = Mutex(State())

    subscript<T: Sendable>(dynamicMember keyPath: WritableKeyPath<State, T>) -> T {
        get { state.withLock { $0[keyPath: keyPath] } }
        set { state.withLock { $0[keyPath: keyPath] = newValue } }
    }

    func syncOrder(cart: Yosemite.POSCart,
                   currency: CurrencyCode) async throws -> Yosemite.Order {
        let onSyncOrderCalled = state.withLock {
            $0.syncOrderWasCalled = true
            $0.syncOrderCallCount += 1
            $0.spySyncOrderCurrency = currency
            return $0.onSyncOrderCalled
        }

        await onSyncOrderCalled?()

        if self.simulateSyncing {
            try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        }

        if let error = self.errorToReturn {
            throw error
        }

        guard let order = self.orderToReturn else {
            throw MockPOSOrderServiceError.noOrderToReturn
        }
        return order
    }

    func loadOrder(orderID: Int64) async throws -> Order {
        let (returnedOrder, onLoadOrderCalled) = state.withLock {
            $0.loadOrderWasCalled = true
            return ($0.orderToReturn, $0.onLoadOrderCalled)
        }
        await onLoadOrderCalled?()

        if let error = self.errorToReturn {
            throw error
        }

        guard let order = returnedOrder else {
            throw MockPOSOrderServiceError.noOrderToReturn
        }
        return order
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {
        let orderWithUpdatedEmail = MockOrders().sampleOrder().copy(billingAddress: .init(firstName: "",
                                                                                 lastName: "",
                                                                                 company: nil,
                                                                                 address1: "",
                                                                                 address2: nil,
                                                                                 city: "",
                                                                                 state: "",
                                                                                 postcode: "",
                                                                                 country: "",
                                                                                 phone: nil,
                                                                                 email: recipientEmail))
        state.withLock {
            $0.updateOrderWasCalled = true
            $0.orderToReturn = orderWithUpdatedEmail
        }
    }

    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {
        let result = state.withLock {
            $0.spyCashPaymentChangeDueAmount = changeDueAmount
            return $0.resultToReturn
        }
        try result.get()
    }

    func markOrderAsCompletedManually(order: Order) async throws {
        let result = state.withLock {
            $0.markOrderAsCompletedManuallyWasCalled = true
            $0.spyMarkOrderAsCompletedManuallyOrder = order
            return $0.resultToReturn
        }
        try result.get()
    }

    func promoteOrderToPending(order: Order) async throws -> Order {
        let (promoted, onPromoteOrderCalled) = state.withLock {
            $0.promoteOrderToPendingWasCalled = true
            $0.spyPromoteOrderToPendingOrder = order
            return ($0.promoteOrderToPendingOverride ?? order, $0.onPromoteOrderCalled)
        }
        await onPromoteOrderCalled?()
        try self.resultToReturn.get()
        return promoted
    }

    func addOrderNote(orderID: Int64, isCustomerNote: Bool, note: String) async throws {
        let result = state.withLock {
            $0.addOrderNoteWasCalled = true
            $0.spyAddOrderNoteOrderID = orderID
            $0.spyAddOrderNoteIsCustomerNote = isCustomerNote
            $0.spyAddOrderNoteText = note
            return $0.addOrderNoteResult ?? $0.resultToReturn
        }
        try result.get()
    }

    func recordScanToPayPaymentMethod(order: Order) async throws {
        let result = state.withLock {
            $0.recordScanToPayPaymentMethodWasCalled = true
            $0.spyRecordScanToPayPaymentMethodOrder = order
            return $0.recordScanToPayPaymentMethodResult ?? $0.resultToReturn
        }
        try result.get()
    }
}

enum MockPOSOrderServiceError: Error {
    case noOrderToReturn
}
