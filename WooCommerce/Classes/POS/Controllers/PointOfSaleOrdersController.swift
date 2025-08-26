import Foundation
import Observation
import enum Yosemite.PointOfSaleOrderServiceError
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import protocol Yosemite.PointOfSaleOrderFetchStrategyFactoryProtocol
import protocol Yosemite.PointOfSaleOrderFetchStrategy
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import class Yosemite.Store

protocol PointOfSaleOrdersControllerProtocol {
    var ordersViewState: OrderListState { get }
    func loadOrders() async
    func refreshOrders() async
    func loadNextOrders() async
}

@Observable final class PointOfSaleOrdersController: PointOfSaleOrdersControllerProtocol {
    var ordersViewState: OrderListState
    private let paginationTracker: AsyncPaginationTracker
    private var fetchStrategy: PointOfSaleOrderFetchStrategy
    private var cachedOrders: [POSOrder] = []

    init(orderFetchStrategyFactory: PointOfSaleOrderFetchStrategyFactoryProtocol,
         initialState: OrderListState = .loading([])) {
        self.ordersViewState = initialState
        self.paginationTracker = .init()
        self.fetchStrategy = orderFetchStrategyFactory.defaultStrategy()
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

            let newOrders = pagedOrders.items
            var allOrders = appendToExistingOrders ? ordersViewState.orders : []
            let uniqueNewOrders = newOrders.filter { newOrder in
                !allOrders.contains(where: { $0.id == newOrder.id })
            }

            if appendToExistingOrders && !uniqueNewOrders.isEmpty {
                allOrders.append(contentsOf: uniqueNewOrders)
            } else if !appendToExistingOrders {
                allOrders = uniqueNewOrders
            }

            if allOrders.isEmpty {
                ordersViewState = .empty
            } else {
                ordersViewState = .loaded(allOrders, hasMoreItems: pagedOrders.hasMorePages)

                if pageNumber == 1 && !appendToExistingOrders {
                    cachedOrders = allOrders
                }
            }
            return pagedOrders.hasMorePages
        } catch PointOfSaleOrderServiceError.requestCancelled {
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
}
