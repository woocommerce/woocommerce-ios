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
    var updateOrderWasCalled = false
    var spySyncOrderCurrency: CurrencyCode?
    var spyCashPaymentChangeDueAmount: String?

    var deleteOrderWasCalled = false
    var deletedOrder: Order?
    var deleteOrderResult: Result<Order, Error> = .success(Order.fake())

    func syncOrder(cart: Yosemite.POSCart,
                   currency: CurrencyCode) async throws -> Yosemite.Order {
        syncOrderWasCalled = true
        spySyncOrderCurrency = currency

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
    
    func deleteOrder(siteID: Int64, order: Yosemite.Order, deletePermanently: Bool, onCompletion: @escaping (Result<Yosemite.Order, any Error>) -> Void) {
        deleteOrderWasCalled = true
        deletedOrder = order
        onCompletion(deleteOrderResult)
    }
}

enum MockPOSOrderServiceError: Error {
    case noOrderToReturn
}
