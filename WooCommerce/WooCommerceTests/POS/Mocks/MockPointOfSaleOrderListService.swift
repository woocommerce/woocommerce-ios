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
            status: .completed,
            formattedTotal: "$25.99",
            formattedSubtotal: "$25.99",
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
                    formattedPrice: "$10.00",
                    formattedTotal: "$20.00",
                    imageSrc: nil,
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 2,
                    name: "Muffin",
                    productID: 102,
                    variationID: 0,
                    quantity: 1,
                    formattedPrice: "$5.99",
                    formattedTotal: "$5.99",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedTotalTax: "$0.00",
            formattedDiscountTotal: nil,
            formattedPaymentTotal: "$25.99",
            formattedNetAmount: nil
        )

        let order2 = POSOrder(
            id: 1002,
            number: "1002",
            dateCreated: baseDate.addingTimeInterval(3600),
            status: .completed,
            formattedTotal: "$15.50",
            formattedSubtotal: "$15.50",
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
                    formattedPrice: "$15.50",
                    formattedTotal: "$15.50",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedTotalTax: "$0.00",
            formattedDiscountTotal: nil,
            formattedPaymentTotal: "$15.50",
            formattedNetAmount: nil
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
            formattedTotal: "$42.75",
            formattedSubtotal: "$42.75",
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
                    formattedPrice: "$12.00",
                    formattedTotal: "$12.00",
                    imageSrc: nil,
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 5,
                    name: "Soup",
                    productID: 105,
                    variationID: 0,
                    quantity: 2,
                    formattedPrice: "$15.38",
                    formattedTotal: "$30.75",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedTotalTax: "$0.00",
            formattedDiscountTotal: nil,
            formattedPaymentTotal: "$42.75",
            formattedNetAmount: nil
        )

        let order4 = POSOrder(
            id: 1004,
            number: "1004",
            dateCreated: baseDate.addingTimeInterval(10800),
            status: .refunded,
            formattedTotal: "$12.00",
            formattedSubtotal: "$12.00",
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
                    formattedPrice: "$12.00",
                    formattedTotal: "$12.00",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [
                POSOrderRefund(refundID: 1001, formattedTotal: "-$12.00", reason: "Customer request")
            ],
            formattedTotalTax: "$0.00",
            formattedDiscountTotal: nil,
            formattedPaymentTotal: "$12.00",
            formattedNetAmount: "$0.00"
        )

        return [order3, order4]
    }
}
