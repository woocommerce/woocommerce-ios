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
    var spyCashPaymentChangeDueAmount: String?

    var onSyncOrderCalled: (@MainActor () async -> Void)?

    func syncOrder(cart: Yosemite.POSCart,
                   currency: CurrencyCode) async throws -> Yosemite.Order {
        syncOrderWasCalled = true
        syncOrderCallCount += 1
        spySyncOrderCurrency = currency

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

    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {
        spyCashPaymentChangeDueAmount = changeDueAmount

        switch resultToReturn {
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
