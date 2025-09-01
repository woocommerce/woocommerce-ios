import Foundation
@testable import Yosemite
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import enum NetworkingCore.OrderStatusEnum
import WooFoundation

final class MockPointOfSaleOrderListService: PointOfSaleOrderListServiceProtocol {
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
            throw PointOfSaleOrderListServiceError.requestFailed
        }

        if let errorToThrow {
            throw errorToThrow
        }

        if shouldReturnZeroOrders {
            return .init(items: [], hasMorePages: false, totalItems: 0)
        }

        if shouldSimulateTwoPages {
            if shouldSimulateThreePages && pageNumber > 1 {
                return .init(
                    items: MockPointOfSaleOrderListService.makeSecondPageOrders(),
                    hasMorePages: true,
                    totalItems: 6
                )
            } else if pageNumber > 1 {
                return .init(
                    items: MockPointOfSaleOrderListService.makeSecondPageOrders(),
                    hasMorePages: false,
                    totalItems: 4
                )
            } else {
                return .init(
                    items: MockPointOfSaleOrderListService.makeInitialOrders(),
                    hasMorePages: shouldSimulateTwoPages,
                    totalItems: 4
                )
            }
        }

        return .init(
            items: (orderPages[safe: pageNumber - 1] ?? []),
            hasMorePages: orderPages.count > pageNumber,
            totalItems: 2
        )
    }
}

extension MockPointOfSaleOrderListService {
    static func makeInitialOrders() -> [POSOrder] {
        let baseDate = Date(timeIntervalSince1970: 1672531200) // Fixed date: Jan 1, 2023

        let order1 = POSOrder(
            id: 1001,
            number: "1001",
            dateCreated: baseDate,
            datePaid: baseDate,
            status: .completed,
            total: "25.99",
            customerEmail: "customer1@example.com",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            lineItems: [
                POSOrderItem(
                    itemID: 1,
                    name: "Coffee",
                    productID: 101,
                    variationID: 0,
                    quantity: 2,
                    price: NSDecimalNumber(string: "10.00"),
                    subtotal: "20.00",
                    total: "20.00",
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 2,
                    name: "Muffin",
                    productID: 102,
                    variationID: 0,
                    quantity: 1,
                    price: NSDecimalNumber(string: "5.99"),
                    subtotal: "5.99",
                    total: "5.99",
                    attributes: []
                )
            ],
            refunds: [],
            currency: "USD",
            currencySymbol: "$",
            discountTotal: "0.00",
            totalTax: "0.00"
        )

        let order2 = POSOrder(
            id: 1002,
            number: "1002",
            dateCreated: baseDate.addingTimeInterval(3600),
            datePaid: baseDate.addingTimeInterval(3600),
            status: .completed,
            total: "15.50",
            customerEmail: "customer2@example.com",
            paymentMethodID: "cod",
            paymentMethodTitle: "Card",
            lineItems: [
                POSOrderItem(
                    itemID: 3,
                    name: "Tea",
                    productID: 103,
                    variationID: 0,
                    quantity: 1,
                    price: NSDecimalNumber(string: "15.50"),
                    subtotal: "15.50",
                    total: "15.50",
                    attributes: []
                )
            ],
            refunds: [],
            currency: "USD",
            currencySymbol: "$",
            discountTotal: "0.00",
            totalTax: "0.00"
        )

        return [order1, order2]
    }

    static func makeSecondPageOrders() -> [POSOrder] {
        let baseDate = Date(timeIntervalSince1970: 1672531200) // Fixed date: Jan 1, 2023

        let order3 = POSOrder(
            id: 1003,
            number: "1003",
            dateCreated: baseDate.addingTimeInterval(7200),
            datePaid: baseDate.addingTimeInterval(7200),
            status: .completed,
            total: "42.75",
            customerEmail: "customer3@example.com",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            lineItems: [
                POSOrderItem(
                    itemID: 4,
                    name: "Sandwich",
                    productID: 104,
                    variationID: 0,
                    quantity: 1,
                    price: NSDecimalNumber(string: "12.00"),
                    subtotal: "12.00",
                    total: "12.00",
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 5,
                    name: "Soup",
                    productID: 105,
                    variationID: 0,
                    quantity: 2,
                    price: NSDecimalNumber(string: "15.375"),
                    subtotal: "30.75",
                    total: "30.75",
                    attributes: []
                )
            ],
            refunds: [],
            currency: "USD",
            currencySymbol: "$",
            discountTotal: "0.00",
            totalTax: "0.00"
        )

        let order4 = POSOrder(
            id: 1004,
            number: "1004",
            dateCreated: baseDate.addingTimeInterval(10800),
            datePaid: baseDate.addingTimeInterval(10800),
            status: .refunded,
            total: "12.00",
            customerEmail: "customer4@example.com",
            paymentMethodID: "cod",
            paymentMethodTitle: "Card",
            lineItems: [
                POSOrderItem(
                    itemID: 6,
                    name: "Cookies",
                    productID: 106,
                    variationID: 0,
                    quantity: 1,
                    price: NSDecimalNumber(string: "12.00"),
                    subtotal: "12.00",
                    total: "12.00",
                    attributes: []
                )
            ],
            refunds: [
                POSOrderRefund(refundID: 1001, total: "-12.00", reason: "Customer request")
            ],
            currency: "USD",
            currencySymbol: "$",
            discountTotal: "0.00",
            totalTax: "0.00"
        )

        return [order3, order4]
    }
}
