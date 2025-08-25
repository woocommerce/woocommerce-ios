import Foundation
@testable import Yosemite
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import enum NetworkingCore.OrderStatusEnum
import WooFoundation

final class MockPointOfSaleOrderService: PointOfSaleOrderServiceProtocol {
    var orderPages: [[Order]] = []
    var errorToThrow: Error?
    var shouldReturnZeroOrders = false
    var shouldSimulateTwoPages = false
    var shouldSimulateThreePages = false
    var shouldThrowError = false

    var spyLastRequestedPageNumber: Int?
    var spyCallCount = 0

    func providePointOfSaleOrders(pageNumber: Int) async throws -> PagedItems<Order> {
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
    static func makeInitialOrders() -> [Order] {
        let baseDate = Date(timeIntervalSince1970: 1672531200) // Fixed date: Jan 1, 2023

        let order1 = Order.fake().copy(
            orderID: 1001,
            number: "1001",
            status: .completed,
            dateCreated: baseDate,
            dateModified: baseDate,
            total: "25.99"
        )

        let order2 = Order.fake().copy(
            orderID: 1002,
            number: "1002",
            status: .completed,
            dateCreated: baseDate.addingTimeInterval(3600),
            dateModified: baseDate.addingTimeInterval(3600),
            total: "15.50"
        )

        return [order1, order2]
    }

    static func makeSecondPageOrders() -> [Order] {
        let baseDate = Date(timeIntervalSince1970: 1672531200) // Fixed date: Jan 1, 2023

        let order3 = Order.fake().copy(
            orderID: 1003,
            number: "1003",
            status: .completed,
            dateCreated: baseDate.addingTimeInterval(7200),
            dateModified: baseDate.addingTimeInterval(7200),
            total: "42.75"
        )

        let order4 = Order.fake().copy(
            orderID: 1004,
            number: "1004",
            status: .refunded,
            dateCreated: baseDate.addingTimeInterval(10800),
            dateModified: baseDate.addingTimeInterval(10800),
            total: "12.00"
        )

        return [order3, order4]
    }
}
