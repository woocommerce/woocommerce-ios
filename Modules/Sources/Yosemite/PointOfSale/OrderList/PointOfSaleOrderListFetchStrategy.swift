import Foundation
import struct NetworkingCore.PagedItems

public protocol PointOfSaleOrderListFetchStrategy {
    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
    func loadOrder(orderID: Int64) async throws -> POSOrder
    var supportsCaching: Bool { get }
    var showsLoadingWithItems: Bool { get }
    var id: String { get }
}

extension PointOfSaleOrderListFetchStrategy {
    var id: String {
        String(describing: type(of: self))
    }
}

struct PointOfSaleDefaultOrderListFetchStrategy: PointOfSaleOrderListFetchStrategy {
    private let orderListService: PointOfSaleOrderListServiceProtocol
    let supportsCaching: Bool = true
    var showsLoadingWithItems: Bool = true

    init(orderListService: PointOfSaleOrderListServiceProtocol) {
        self.orderListService = orderListService
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderListService.providePointOfSaleOrders(pageNumber: pageNumber)
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        try await orderListService.loadOrder(orderID: orderID)
    }
}

struct PointOfSaleSearchOrderListFetchStrategy: PointOfSaleOrderListFetchStrategy {
    private let orderListService: PointOfSaleOrderListServiceProtocol
    private let searchTerm: String

    var supportsCaching: Bool = false
    var showsLoadingWithItems = false

    init(orderListService: PointOfSaleOrderListServiceProtocol, searchTerm: String) {
        self.orderListService = orderListService
        self.searchTerm = searchTerm
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderListService.searchPointOfSaleOrders(searchTerm: searchTerm, pageNumber: pageNumber)
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        try await orderListService.loadOrder(orderID: orderID)
    }
}
