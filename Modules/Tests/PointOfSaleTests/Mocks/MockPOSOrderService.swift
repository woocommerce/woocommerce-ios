import Foundation
@testable import Yosemite
import WooFoundation

class MockPOSOrderService: POSOrderServiceProtocol {
    var simulateSyncing = false
    var orderToReturn: Order?
    var errorToReturn: Error?
    // This does not replace the previous `errorToReturn`/`orderToReturn` only to keep the changes small.
    var resultToReturn: Result<Void, Error> = .success(())

    var syncOrderWasCalled = false
    var syncOrderCallCount = 0
    var updateOrderWasCalled = false
    var spySyncOrderCurrency: CurrencyCode?
    var spySyncOrderStaffUserID: Int64?
    var spyCashPaymentChangeDueAmount: String?

    var onSyncOrderCalled: (@MainActor () async -> Void)?

    func syncOrder(cart: Yosemite.POSCart,
                   currency: CurrencyCode,
                   staffUserID: Int64?) async throws -> Yosemite.Order {
        syncOrderWasCalled = true
        syncOrderCallCount += 1
        spySyncOrderCurrency = currency
        spySyncOrderStaffUserID = staffUserID

        await onSyncOrderCalled?()

        if simulateSyncing {
            try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        }

        if let error = errorToReturn {
            throw error
        }

        guard let order = orderToReturn else {
            throw MockPOSOrderServiceError.noOrderToReturn
        }
        return order
    }

    var loadOrderWasCalled = false
    func loadOrder(orderID: Int64) async throws -> Order {
        loadOrderWasCalled = true

        if let error = errorToReturn {
            throw error
        }

        guard let order = orderToReturn else {
            throw MockPOSOrderServiceError.noOrderToReturn
        }
        return order
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {
        updateOrderWasCalled = true

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
        orderToReturn = orderWithUpdatedEmail
    }

    var spyCashPaymentStaffUserID: Int64?
    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?, staffUserID: Int64?) async throws {
        spyCashPaymentChangeDueAmount = changeDueAmount
        spyCashPaymentStaffUserID = staffUserID

        switch resultToReturn {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    var markOrderAsCompletedManuallyWasCalled = false
    var spyMarkOrderAsCompletedManuallyOrder: Order?
    var spyMarkOrderAsCompletedManuallyStaffUserID: Int64?
    func markOrderAsCompletedManually(order: Order, staffUserID: Int64?) async throws {
        markOrderAsCompletedManuallyWasCalled = true
        spyMarkOrderAsCompletedManuallyOrder = order
        spyMarkOrderAsCompletedManuallyStaffUserID = staffUserID
        switch resultToReturn {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    var promoteOrderToPendingWasCalled = false
    var spyPromoteOrderToPendingOrder: Order?
    var spyPromoteOrderToPendingStaffUserID: Int64?
    var promoteOrderToPendingOverride: Order?
    func promoteOrderToPending(order: Order, staffUserID: Int64?) async throws -> Order {
        promoteOrderToPendingWasCalled = true
        spyPromoteOrderToPendingOrder = order
        spyPromoteOrderToPendingStaffUserID = staffUserID
        switch resultToReturn {
        case .success:
            return promoteOrderToPendingOverride ?? order
        case .failure(let error):
            throw error
        }
    }

    var addOrderNoteWasCalled = false
    var spyAddOrderNoteOrderID: Int64?
    var spyAddOrderNoteIsCustomerNote: Bool?
    var spyAddOrderNoteText: String?
    /// When non-nil, overrides `resultToReturn` for `addOrderNote` calls only.
    var addOrderNoteResult: Result<Void, Error>?
    func addOrderNote(orderID: Int64, isCustomerNote: Bool, note: String) async throws {
        addOrderNoteWasCalled = true
        spyAddOrderNoteOrderID = orderID
        spyAddOrderNoteIsCustomerNote = isCustomerNote
        spyAddOrderNoteText = note
        switch addOrderNoteResult ?? resultToReturn {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

enum MockPOSOrderServiceError: Error {
    case noOrderToReturn
}
