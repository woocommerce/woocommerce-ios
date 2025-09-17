import Foundation
import struct NetworkingCore.PagedItems

public protocol POSOrderListFetchStrategy {
    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
    func loadOrder(orderID: Int64) async throws -> POSOrder
    var supportsCaching: Bool { get }
    var showsLoadingWithItems: Bool { get }
    var id: String { get }
}

extension POSOrderListFetchStrategy {
    var id: String {
        String(describing: type(of: self))
    }
}

struct POSDefaultOrderListFetchStrategy: POSOrderListFetchStrategy {
    private let orderListService: POSOrderListServiceProtocol
    let supportsCaching: Bool = true
    var showsLoadingWithItems: Bool = true

    init(orderListService: POSOrderListServiceProtocol) {
        self.orderListService = orderListService
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderListService.providePointOfSaleOrders(pageNumber: pageNumber)
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        try await orderListService.loadOrder(orderID: orderID)
    }
}

struct POSSearchOrderListFetchStrategy: POSOrderListFetchStrategy {
    private let orderListService: POSOrderListServiceProtocol
    private let searchTerm: String

    var supportsCaching: Bool = false
    var showsLoadingWithItems = false

    init(orderListService: POSOrderListServiceProtocol, searchTerm: String) {
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
