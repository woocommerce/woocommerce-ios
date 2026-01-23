import Foundation
@testable import Yosemite
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import enum NetworkingCore.OrderStatusEnum
import WooFoundation

final class MockPOSOrderListService: POSOrderListServiceProtocol {
    var orderPages: [[POSOrder]] = []
    var searchOrderPages: [[POSOrder]] = []
    var errorToThrow: Error?
    var shouldReturnZeroOrders = false
    var shouldSimulateTwoPages = false
    var shouldSimulateThreePages = false
    var shouldThrowError = false

    var spyLastRequestedPageNumber: Int?
    var spyCallCount = 0
    var spyLastSearchTerm: String?
    var lastSearchTerm: String?

    // LoadOrder properties
    var loadOrderResult: POSOrder?
    var loadOrderWasCalled = false
    var lastLoadOrderID: Int64?

    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        spyLastRequestedPageNumber = pageNumber
        spyCallCount += 1

        if shouldThrowError {
            throw POSOrderListServiceError.requestFailed
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
                    items: MockPOSOrderListService.makeSecondPageOrders(),
                    hasMorePages: true,
                    totalItems: 6
                )
            } else if pageNumber > 1 {
                return .init(
                    items: MockPOSOrderListService.makeSecondPageOrders(),
                    hasMorePages: false,
                    totalItems: 4
                )
            } else {
                return .init(
                    items: MockPOSOrderListService.makeInitialOrders(),
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

    func searchPointOfSaleOrders(searchTerm: String, pageNumber: Int) async throws -> PagedItems<POSOrder> {
        spyLastSearchTerm = searchTerm
        lastSearchTerm = searchTerm
        spyLastRequestedPageNumber = pageNumber
        spyCallCount += 1

        if shouldThrowError {
            throw POSOrderListServiceError.requestFailed
        }

        if let errorToThrow {
            throw errorToThrow
        }

        if shouldReturnZeroOrders {
            return .init(items: [], hasMorePages: false, totalItems: 0)
        }

        // Use searchOrderPages if available, otherwise filter based on search term
        if !searchOrderPages.isEmpty {
            return .init(
                items: (searchOrderPages[safe: pageNumber - 1] ?? []),
                hasMorePages: searchOrderPages.count > pageNumber,
                totalItems: searchOrderPages.flatMap { $0 }.count
            )
        }

        // For testing purposes, return filtered results based on search term
        let allOrders = MockPOSOrderListService.makeInitialOrders()
        let filteredOrders = allOrders.filter { order in
            order.number.contains(searchTerm) ||
            order.customerEmail?.contains(searchTerm) == true ||
            order.lineItems.contains { $0.name.lowercased().contains(searchTerm.lowercased()) }
        }

        return .init(
            items: filteredOrders,
            hasMorePages: false,
            totalItems: filteredOrders.count
        )
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        loadOrderWasCalled = true
        lastLoadOrderID = orderID

        if shouldThrowError {
            throw POSOrderListServiceError.requestFailed
        }

        if let errorToThrow {
            throw errorToThrow
        }

        if let result = loadOrderResult {
            return result
        }

        // Fallback - find order from existing orders
        let allOrders = MockPOSOrderListService.makeInitialOrders() + MockPOSOrderListService.makeSecondPageOrders()
        if let foundOrder = allOrders.first(where: { $0.id == orderID }) {
            return foundOrder
        }

        throw POSOrderListServiceError.requestFailed
    }
}

extension MockPOSOrderListService {
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
                    quantity: 2,
                    price: 10.00,
                    totalTax: 0,
                    formattedPrice: "$10.00",
                    formattedTotal: "$20.00",
                    imageSrc: nil,
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 2,
                    name: "Muffin",
                    quantity: 1,
                    price: 5.99,
                    totalTax: 0,
                    formattedPrice: "$5.99",
                    formattedTotal: "$5.99",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
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
            paymentMethodID: "woocommerce_payments",
            paymentMethodTitle: "Card",
            lineItems: [
                POSOrderItem(
                    itemID: 3,
                    name: "Tea",
                    quantity: 1,
                    price: 15.50,
                    totalTax: 0,
                    formattedPrice: "$15.50",
                    formattedTotal: "$15.50",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
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
                    quantity: 1,
                    price: 12.00,
                    totalTax: 0,
                    formattedPrice: "$12.00",
                    formattedTotal: "$12.00",
                    imageSrc: nil,
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 5,
                    name: "Soup",
                    quantity: 2,
                    price: 15.38,
                    totalTax: 0,
                    formattedPrice: "$15.38",
                    formattedTotal: "$30.75",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
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
            paymentMethodID: "woocommerce_payments",
            paymentMethodTitle: "Card",
            lineItems: [
                POSOrderItem(
                    itemID: 6,
                    name: "Cookies",
                    quantity: 1,
                    price: 12.00,
                    totalTax: 0,
                    formattedPrice: "$12.00",
                    formattedTotal: "$12.00",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [
                POSOrderRefund(refundID: 1001, formattedTotal: "-$12.00", reason: "Customer request")
            ],
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$12.00",
            formattedNetAmount: "$0.00"
        )

        return [order3, order4]
    }

    static func makeSearchOrders() -> [POSOrder] {
        let baseDate = Date(timeIntervalSince1970: 1672531200) // Fixed date: Jan 1, 2023

        let searchOrder = POSOrder(
            id: 2001,
            number: "2001",
            dateCreated: baseDate.addingTimeInterval(14400),
            status: .completed,
            formattedTotal: "$18.50",
            formattedSubtotal: "$18.50",
            customerEmail: "search@example.com",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            lineItems: [
                POSOrderItem(
                    itemID: 7,
                    name: "Test Product",
                    quantity: 1,
                    price: 18.50,
                    totalTax: 0,
                    formattedPrice: "$18.50",
                    formattedTotal: "$18.50",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$18.50",
            formattedNetAmount: nil
        )

        return [searchOrder]
    }
}
