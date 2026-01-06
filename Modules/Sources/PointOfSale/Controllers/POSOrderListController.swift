import Foundation
import Observation
import enum Yosemite.POSOrderListServiceError
import protocol Yosemite.POSOrderListServiceProtocol
import protocol Yosemite.POSOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.POSOrderListFetchStrategy
import protocol Yosemite.POSRefundsServiceProtocol
import class Yosemite.POSRefundsService
import struct Yosemite.POSOrder
import struct Yosemite.POSRefund
import struct Yosemite.POSOrderItem
import class Yosemite.Store
import class Yosemite.AsyncPaginationTracker
import protocol Experiments.FeatureFlagService

protocol POSOrderListControllerProtocol {
    var ordersViewState: POSOrderListState { get }
    var selectedOrder: POSOrder? { get }
    func loadOrders() async
    func refreshOrders() async
    func loadNextOrders() async
    func selectOrder(_ order: POSOrder?)
    func updateOrder(orderID: Int64) async throws
}

protocol POSSearchingOrderListControllerProtocol: POSOrderListControllerProtocol {
    func searchOrders(searchTerm: String) async
    func clearSearchOrders()
}

enum POSOrderListSelectedOrderRefundsState {
    case idle
    case loading
    case loaded([POSRefund])
    case failed(Error)
}

@Observable final class POSOrderListController: POSSearchingOrderListControllerProtocol {
    var ordersViewState: POSOrderListState
    private var strategyPaginationTracker: [String: AsyncPaginationTracker] = [:]
    private var fetchStrategy: POSOrderListFetchStrategy
    private var cachedOrders: [POSOrder] = []
    private(set) var selectedOrder: POSOrder?
    private(set) var selectedOrderRefundsState: POSOrderListSelectedOrderRefundsState = .idle
    private var refundsTask: Task<Void, Never>?
    private let orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol
    private let refundsService: POSRefundsServiceProtocol
    private let featureFlags: POSFeatureFlagProviding
    private var paginationTracker: AsyncPaginationTracker {
        if let existing = strategyPaginationTracker[fetchStrategy.id] {
             return existing
         }
         let tracker = AsyncPaginationTracker()
         strategyPaginationTracker[fetchStrategy.id] = tracker
         return tracker
    }

    init(orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol,
         refundsService: POSRefundsServiceProtocol,
         featureFlags: POSFeatureFlagProviding,
         initialState: POSOrderListState = .loading([])) {
        self.ordersViewState = initialState
        self.orderListFetchStrategyFactory = orderListFetchStrategyFactory
        self.fetchStrategy = orderListFetchStrategyFactory.defaultStrategy()
        self.refundsService = refundsService
        self.featureFlags = featureFlags
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
                                          context: POSOrderListState.InlineErrorContext.pagination)
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
                                              context: POSOrderListState.InlineErrorContext.refresh)
            }
        }
    }

    private func setLoadingState() {
        if !fetchStrategy.showsLoadingWithItems {
            ordersViewState = .loading([])
            return
        }

        let orders = ordersViewState.orders
        let isInitialState = ordersViewState.isLoading && orders.isEmpty
        if !isInitialState {
            ordersViewState = .loading(orders)
        }
    }

    @MainActor
    private func fetchOrders(pageNumber: Int, appendToExistingOrders: Bool = true) async throws -> Bool {
        let startTime = Date()
        do {
            let pagedOrders = try await fetchStrategy.fetchOrders(pageNumber: pageNumber)
            let endTime = Date()
            let millisecondsSinceRequestSent = Int(endTime.timeIntervalSince(startTime) * 1000)

            let existingOrders = appendToExistingOrders ? ordersViewState.orders : []
            let uniqueNewOrders = pagedOrders.items.filter { newOrder in
                !existingOrders.contains(where: { $0.id == newOrder.id })
            }
            let allOrders = appendToExistingOrders ? existingOrders + uniqueNewOrders : uniqueNewOrders

            ordersViewState = allOrders.isEmpty ? .empty : .loaded(allOrders, hasMoreItems: pagedOrders.hasMorePages)

            if let selectedOrderID = selectedOrder?.id,
               let updatedSelectedOrder = allOrders.first(where: { $0.id == selectedOrderID }) {
                selectedOrder = updatedSelectedOrder
            }

            if fetchStrategy.supportsCaching {
                cachedOrders = allOrders
            }

            if pageNumber > 1 {
                fetchStrategy.trackNextPageLoaded(pageNumber: pageNumber)
            } else {
                fetchStrategy.trackFetched(millisecondsSinceRequestSent: millisecondsSinceRequestSent)
            }

            return pagedOrders.hasMorePages
        } catch POSOrderListServiceError.requestCancelled {
            return true
        }
    }

    @MainActor
    private func setCachedData() {
        guard fetchStrategy.supportsCaching else {
            return
        }

        guard !ordersViewState.orders.isEmpty || !cachedOrders.isEmpty else {
            return
        }

        ordersViewState = .loading(cachedOrders)
    }

    @MainActor
    func selectOrder(_ order: POSOrder?) {
        selectedOrder = order
        selectedOrderRefundsState = .idle

        if featureFlags.isFeatureFlagEnabled(.pointOfSaleRefundsi1) {
            fetchRefundsOfSelectedOrder()
        }
    }

    @MainActor
    func searchOrders(searchTerm: String) async {
        fetchStrategy = orderListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm)
        ordersViewState = .loading([])
        await loadFirstPage()
    }

    @MainActor
    func clearSearchOrders() {
        fetchStrategy = orderListFetchStrategyFactory.defaultStrategy()
        if cachedOrders.isNotEmpty {
            ordersViewState = .loaded(cachedOrders, hasMoreItems: true)
        } else {
            ordersViewState = .loading([])
            Task {
                await loadFirstPage()
            }
        }
    }

    @MainActor
    func updateOrder(orderID: Int64) async throws {
        let updatedOrder = try await fetchStrategy.loadOrder(orderID: orderID)
        let updatedOrders = ordersViewState.orders.map { order in
            order.id == orderID ? updatedOrder : order
        }

        ordersViewState = ordersViewState.updatingOrders(with: updatedOrders)
        cachedOrders = cachedOrders.map { order in
            order.id == orderID ? updatedOrder : order
        }

        if selectedOrder?.id == orderID {
            selectedOrder = updatedOrder
        }
    }

    @MainActor
    private func fetchRefundsOfSelectedOrder() {
        refundsTask?.cancel()
        guard let order = selectedOrder else { return }

        selectedOrderRefundsState = .loading
        let orderID = order.id

        refundsTask = Task { [weak self] in
            guard let self else { return }
            do {
                let refunds = try await self.refundsService.providePointOfSaleRefunds(for: order)
                await MainActor.run {
                    guard self.selectedOrder?.id == orderID else { return }
                    self.selectedOrderRefundsState = .loaded(refunds)
                }
            }
            catch is CancellationError {}
            catch {
                await MainActor.run {
                    guard self.selectedOrder?.id == orderID else { return }
                    self.selectedOrderRefundsState = .failed(error)
                }
            }
        }
    }
}
