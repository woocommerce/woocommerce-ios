import Foundation
@testable import Yosemite
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import enum NetworkingCore.OrderStatusEnum
import WooFoundation

final class MockPointOfSaleOrderService: PointOfSaleOrderServiceProtocol {
    var orderPages: [[POSOrder]] = []
    var errorToThrow: Error?
    var shouldReturnZeroOrders = false
    var shouldSimulateTwoPages = false
    var shouldSimulateThreePages = false
    var shouldThrowError = false

    var spyLastRequestedPageNumber: Int?
    var spyCallCount = 0

    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        spyLastRequestedPageNumber = pageNumber
        spyCallCount += 1

        if shouldThrowError {
            throw PointOfSaleOrderServiceError.requestFailed
        }

        if let errorToThrow {
            throw errorToThrow
        }

        if shouldReturnZeroOrders {
            return .init(items: [], hasMorePages: false, totalItems: 0)
        }

        if shouldSimulateTwoPages {
            if shouldSimulateThreePages && pageNumber > 1 {
                return .init(items: MockPointOfSaleOrderService.makeSecondPageOrders(), hasMorePages: true, totalItems: 6)
            } else if pageNumber > 1 {
                return .init(items: MockPointOfSaleOrderService.makeSecondPageOrders(), hasMorePages: false, totalItems: 4)
            } else {
                return .init(items: MockPointOfSaleOrderService.makeInitialOrders(), hasMorePages: shouldSimulateTwoPages, totalItems: 4)
            }
        }

        return .init(items: (orderPages[safe: pageNumber - 1] ?? []), hasMorePages: orderPages.count > pageNumber, totalItems: 2)
    }
}

extension MockPointOfSaleOrderService {
    static func makeInitialOrders() -> [POSOrder] {
        let baseDate = Date(timeIntervalSince1970: 1672531200) // Fixed date: Jan 1, 2023

        let order1 = POSOrder(
            id: 1001,
            number: "1001",
            dateCreated: baseDate,
            status: .completed,
            total: "25.99",
            customerEmail: "customer1@example.com",
            paymentMethodTitle: "Cash",
            lineItems: [
                POSOrderItem(itemID: 1, name: "Coffee", quantity: 2, total: "20.00"),
                POSOrderItem(itemID: 2, name: "Muffin", quantity: 1, total: "5.99")
            ],
            currency: "USD",
            currencySymbol: "$"
        )

        let order2 = POSOrder(
            id: 1002,
            number: "1002",
            dateCreated: baseDate.addingTimeInterval(3600),
            status: .completed,
            total: "15.50",
            customerEmail: "customer2@example.com",
            paymentMethodTitle: "Card",
            lineItems: [
                POSOrderItem(itemID: 3, name: "Tea", quantity: 1, total: "15.50")
            ],
            currency: "USD",
            currencySymbol: "$"
        )

        return [order1, order2]
    }

    static func makeSecondPageOrders() -> [POSOrder] {
        let baseDate = Date(timeIntervalSince1970: 1672531200) // Fixed date: Jan 1, 2023

        let order3 = POSOrder(
            id: 1003,
            number: "1003",
            dateCreated: baseDate.addingTimeInterval(7200),
            status: .completed,
            total: "42.75",
            customerEmail: "customer3@example.com",
            paymentMethodTitle: "Cash",
            lineItems: [
                POSOrderItem(itemID: 4, name: "Sandwich", quantity: 1, total: "12.00"),
                POSOrderItem(itemID: 5, name: "Soup", quantity: 2, total: "30.75")
            ],
            currency: "USD",
            currencySymbol: "$"
        )

        let order4 = POSOrder(
            id: 1004,
            number: "1004",
            dateCreated: baseDate.addingTimeInterval(10800),
            status: .refunded,
            total: "12.00",
            customerEmail: "customer4@example.com",
            paymentMethodTitle: "Card",
            lineItems: [
                POSOrderItem(itemID: 6, name: "Cookies", quantity: 1, total: "12.00")
            ],
            refunds: [
                POSOrderRefund(refundID: 1001, total: "12.00", reason: "Customer request")
            ],
            currency: "USD",
            currencySymbol: "$"
        )

        return [order3, order4]
    }
}
