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

    // For controlling sync timing in tests
    private var syncContinuation: CheckedContinuation<Void, Never>?
    private var shouldBlockSync = false

    /// Blocks the next sync operation until `resumeBlockedSync()` is called
    func blockNextSync() {
        shouldBlockSync = true
    }

    /// Resumes a blocked sync operation
    func resumeBlockedSync() {
        syncContinuation?.resume()
        syncContinuation = nil
        shouldBlockSync = false
    }

    func syncOrder(cart: Yosemite.POSCart,
                   currency: CurrencyCode) async throws -> Yosemite.Order {
        syncOrderWasCalled = true
        spySyncOrderCurrency = currency

        if shouldBlockSync {
            shouldBlockSync = false // Only block the first call
            await withCheckedContinuation { continuation in
                syncContinuation = continuation
            }
        } else if simulateSyncing {
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

    func fetchOrder(orderID: Int64) async throws -> Order {
        if let error = errorToReturn {
            throw error
        }
        guard let order = orderToReturn else {
            throw MockPOSOrderServiceError.noOrderToReturn
        }
        return order
    }
}

enum MockPOSOrderServiceError: Error {
    case noOrderToReturn
}
