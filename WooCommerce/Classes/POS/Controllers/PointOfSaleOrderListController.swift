import Foundation
import Observation
import enum Yosemite.PointOfSaleOrderListServiceError
import protocol Yosemite.PointOfSaleOrderListServiceProtocol
import protocol Yosemite.PointOfSaleOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.PointOfSaleOrderListFetchStrategy
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import class Yosemite.Store

protocol PointOfSaleOrderListControllerProtocol {
    var ordersViewState: OrderListState { get }
    var selectedOrder: POSOrder? { get }
    func loadOrders() async
    func refreshOrders() async
    func loadNextOrders() async
    func selectOrder(_ order: POSOrder?)
}

@Observable final class PointOfSaleOrderListController: PointOfSaleOrderListControllerProtocol {
    var ordersViewState: OrderListState
    private let paginationTracker: AsyncPaginationTracker
    private var fetchStrategy: PointOfSaleOrderListFetchStrategy
    private var cachedOrders: [POSOrder] = []
    private(set) var selectedOrder: POSOrder?

    init(orderListFetchStrategyFactory: PointOfSaleOrderListFetchStrategyFactoryProtocol,
         initialState: OrderListState = .loading([])) {
        self.ordersViewState = initialState
        self.paginationTracker = .init()
        self.fetchStrategy = orderListFetchStrategyFactory.defaultStrategy()
    }

    @MainActor
    func loadOrders() async {
        setCachedData()
        setLoadingState()
        await loadFirstPage()
    }

    @MainActor
    func refreshOrders() async {
        await loadFirstPage()
    }

    @MainActor
    func loadNextOrders() async {
        guard paginationTracker.hasNextPage else {
            return
        }
        let currentOrders = ordersViewState.orders
        ordersViewState = .loading(currentOrders)
        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchOrders(pageNumber: pageNumber)
            }
        } catch {
            ordersViewState = .inlineError(currentOrders,
                                          error: .errorOnLoadingOrdersNextPage(error: error),
                                          context: OrderListState.InlineErrorContext.pagination)
        }
    }

    @MainActor
    private func loadFirstPage() async {
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchOrders(pageNumber: pageNumber, appendToExistingOrders: false)
            }
        } catch {
            let orders = ordersViewState.orders
            if orders.isEmpty {
                ordersViewState = .error(.errorOnLoadingOrders(error: error))
            } else {
                ordersViewState = .inlineError(orders,
                                              error: .errorOnLoadingOrders(error: error),
                                              context: OrderListState.InlineErrorContext.refresh)
            }
        }
    }

    private func setLoadingState() {
        let orders = ordersViewState.orders
        let isInitialState = ordersViewState.isLoading && orders.isEmpty
        if !isInitialState {
            ordersViewState = .loading(orders)
        }
    }

    @MainActor
    private func fetchOrders(pageNumber: Int, appendToExistingOrders: Bool = true) async throws -> Bool {
        do {
            let pagedOrders = try await fetchStrategy.fetchOrders(pageNumber: pageNumber)

            let existingOrders = appendToExistingOrders ? ordersViewState.orders : []
            let uniqueNewOrders = pagedOrders.items.filter { newOrder in
                !existingOrders.contains(where: { $0.id == newOrder.id })
            }
            let allOrders = appendToExistingOrders ? existingOrders + uniqueNewOrders : uniqueNewOrders

            ordersViewState = allOrders.isEmpty ? .empty : .loaded(allOrders, hasMoreItems: pagedOrders.hasMorePages)

            if pageNumber == 1 && !appendToExistingOrders {
                cachedOrders = allOrders
            }

            return pagedOrders.hasMorePages
        } catch PointOfSaleOrderListServiceError.requestCancelled {
            return true
        }
    }

    @MainActor
    private func setCachedData() {
        guard !ordersViewState.orders.isEmpty || !cachedOrders.isEmpty else {
            return
        }

        ordersViewState = .loading(cachedOrders)
    }

    @MainActor
    func selectOrder(_ order: POSOrder?) {
        selectedOrder = order
    }
}
