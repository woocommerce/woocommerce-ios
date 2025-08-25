import Foundation
import Observation
import enum Yosemite.PointOfSaleOrderServiceError
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import class Yosemite.Store

protocol PointOfSaleOrdersControllerProtocol {
    var ordersViewState: OrdersViewState { get }
    func loadOrders() async
    func refreshOrders() async
    func loadNextOrders() async
}

@Observable final class PointOfSaleOrdersController: PointOfSaleOrdersControllerProtocol {
    var ordersViewState: OrdersViewState
    private let paginationTracker: AsyncPaginationTracker
    private var orderProvider: PointOfSaleOrderServiceProtocol
    private var cachedOrders: [POSOrder] = []

    init(orderProvider: PointOfSaleOrderServiceProtocol,
         initialState: OrdersViewState = OrdersViewState(containerState: .loading,
                                                        ordersState: .loading([]))) {
        self.orderProvider = orderProvider
        self.ordersViewState = initialState
        self.paginationTracker = .init()
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
        let currentOrders = ordersViewState.ordersState.orders
        ordersViewState.containerState = .content
        ordersViewState.ordersState = .loading(currentOrders)
        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchOrders(pageNumber: pageNumber)
            }
        } catch {
            ordersViewState.containerState = .content
            ordersViewState.ordersState = .inlineError(currentOrders,
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
            let orders = ordersViewState.ordersState.orders
            if orders.isEmpty {
                ordersViewState = OrdersViewState(containerState: .content, ordersState: .error(.errorOnLoadingOrders(error: error)))
            } else {
                ordersViewState = OrdersViewState(containerState: .content,
                                                ordersState: .inlineError(orders, error: .errorOnLoadingOrders(error: error),
                                                                          context: OrderListState.InlineErrorContext.refresh))
            }
        }
    }

    private func setLoadingState() {
        let orders = ordersViewState.ordersState.orders
        let isInitialState = ordersViewState.containerState == .loading
        if !isInitialState {
            ordersViewState.ordersState = .loading(orders)
        }
    }

    @MainActor
    private func fetchOrders(pageNumber: Int, appendToExistingOrders: Bool = true) async throws -> Bool {
        do {
            let pagedOrders = try await orderProvider.providePointOfSaleOrders(pageNumber: pageNumber)

            let newOrders = pagedOrders.items
            var allOrders = appendToExistingOrders ? ordersViewState.ordersState.orders : []
            let uniqueNewOrders = newOrders.filter { newOrder in
                !allOrders.contains(where: { $0.id == newOrder.id })
            }
            allOrders.append(contentsOf: uniqueNewOrders)

            if allOrders.isEmpty {
                ordersViewState.containerState = .content
                ordersViewState.ordersState = .empty
            } else {
                ordersViewState.containerState = .content
                ordersViewState.ordersState = .loaded(allOrders, hasMoreItems: pagedOrders.hasMorePages)

                // Cache the orders if this is the first page
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
        guard !ordersViewState.ordersState.orders.isEmpty, !cachedOrders.isEmpty else {
            return
        }

        ordersViewState.containerState = .content
        ordersViewState.ordersState = .loading(cachedOrders)
    }
}
