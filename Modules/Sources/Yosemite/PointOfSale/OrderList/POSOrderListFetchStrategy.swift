import Foundation
import struct NetworkingCore.PagedItems

public protocol POSOrderListFetchStrategy {
    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder>
    func loadOrder(orderID: Int64) async throws -> POSOrder
    func trackFetched(millisecondsSinceRequestSent: Int)
    func trackNextPageLoaded(pageNumber: Int)
    var supportsCaching: Bool { get }
    var showsCachedDataWhileLoading: Bool { get }
    var id: String { get }
}

extension POSOrderListFetchStrategy {
    var id: String {
        String(describing: type(of: self))
    }
}

struct POSDefaultOrderListFetchStrategy: POSOrderListFetchStrategy {
    private let orderListService: POSOrderListServiceProtocol
    private let analytics: POSOrderListFetchAnalyticsTracking
    let supportsCaching: Bool = true
    var showsCachedDataWhileLoading: Bool = true

    init(orderListService: POSOrderListServiceProtocol, analytics: POSOrderListFetchAnalyticsTracking) {
        self.orderListService = orderListService
        self.analytics = analytics
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderListService.providePointOfSaleOrders(pageNumber: pageNumber)
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        try await orderListService.loadOrder(orderID: orderID)
    }

    func trackFetched(millisecondsSinceRequestSent: Int) {
        analytics.trackOrdersFetchComplete(millisecondsSinceRequestSent: millisecondsSinceRequestSent)
    }

    func trackNextPageLoaded(pageNumber: Int) {
        analytics.trackOrdersNextPageLoaded(pageNumber: pageNumber)
    }
}

struct POSSearchOrderListFetchStrategy: POSOrderListFetchStrategy {
    private let orderListService: POSOrderListServiceProtocol
    private let searchTerm: String
    private let analytics: POSOrderListFetchAnalyticsTracking

    var supportsCaching: Bool = false
    var showsCachedDataWhileLoading = false

    init(orderListService: POSOrderListServiceProtocol, searchTerm: String, analytics: POSOrderListFetchAnalyticsTracking) {
        self.orderListService = orderListService
        self.searchTerm = searchTerm
        self.analytics = analytics
    }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        try await orderListService.searchPointOfSaleOrders(searchTerm: searchTerm, pageNumber: pageNumber)
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        try await orderListService.loadOrder(orderID: orderID)
    }

    func trackFetched(millisecondsSinceRequestSent: Int) {
        analytics.trackOrdersSearchResultsFetchComplete(millisecondsSinceRequestSent: millisecondsSinceRequestSent)
    }

    func trackNextPageLoaded(pageNumber: Int) {
        analytics.trackOrdersNextPageLoaded(pageNumber: pageNumber)
    }
}
