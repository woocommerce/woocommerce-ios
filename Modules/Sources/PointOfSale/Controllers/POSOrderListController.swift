import Foundation
import Observation
import enum Yosemite.POSOrderListServiceError
import protocol Yosemite.POSOrderListServiceProtocol
import protocol Yosemite.POSOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.POSOrderListFetchStrategy
import protocol Yosemite.POSRefundsServiceProtocol
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderCustomAmount
import struct Yosemite.POSOrderRefund
import struct Yosemite.POSRefundItem
import class Yosemite.AsyncPaginationTracker
import protocol Experiments.FeatureFlagService
import CocoaLumberjackSwift

protocol POSOrderListControllerProtocol {
    var ordersViewState: POSOrderListState { get }
    var selectedOrder: POSOrder? { get }
    var isLoadingOrderRefunds: Bool { get }
    var orderDetailsItemsState: POSOrderDetailsItemsState { get }
    var displayedLineItems: [POSOrderItem] { get }
    var displayedCustomAmounts: [POSOrderCustomAmount] { get }
    func loadOrders() async
    func refreshOrders() async
    func loadNextOrders() async
    func selectOrder(_ order: POSOrder?)
    func updateOrder(orderID: Int64) async throws
    func loadOrderRefunds() async
}

protocol POSSearchingOrderListControllerProtocol: POSOrderListControllerProtocol {
    func searchOrders(searchTerm: String) async
    func clearSearchOrders()
}

enum POSOrderDetailsItemsState: Equatable {
    case loading(rowCount: Int)
    case loaded(lineItems: [POSOrderItem], customAmounts: [POSOrderCustomAmount], refundedItems: [POSRefundItem])
}

private enum POSOrderRefundDetailsState {
    case needsLoading
    case loading
    /// Detailed refunds (with items) for the order — fetched, or already present in the order payload.
    case loaded([POSOrderRefund])
    case failed

    var isLoading: Bool {
        switch self {
        case .needsLoading, .loading:
            return true
        case .loaded, .failed:
            return false
        }
    }
}

@Observable final class POSOrderListController: POSSearchingOrderListControllerProtocol {
    var ordersViewState: POSOrderListState
    private var strategyPaginationTracker: [String: AsyncPaginationTracker] = [:]
    private var fetchStrategy: POSOrderListFetchStrategy
    private var cachedOrders: [POSOrder] = []
    private(set) var selectedOrder: POSOrder?
    /// Refund details fetch state per order. `.loaded` caches the fetched refunds so list refreshes,
    /// which rebuild orders from summary data, don't lose them or re-show the loading skeleton.
    private var refundDetailsByOrderID: [Int64: POSOrderRefundDetailsState] = [:]
    private let orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol
    private let refundsService: POSRefundsServiceProtocol
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
         initialState: POSOrderListState = .loading([])) {
        self.ordersViewState = initialState
        self.orderListFetchStrategyFactory = orderListFetchStrategyFactory
        self.fetchStrategy = orderListFetchStrategyFactory.defaultStrategy()
        self.refundsService = refundsService
    }

    @MainActor
    var isLoadingOrderRefunds: Bool {
        guard let selectedOrder else {
            return false
        }
        return refundDetailsState(for: selectedOrder).isLoading
    }

    @MainActor
    var orderDetailsItemsState: POSOrderDetailsItemsState {
        guard let order = selectedOrder else {
            return .loaded(lineItems: [], customAmounts: [], refundedItems: [])
        }

        if refundDetailsState(for: order).isLoading {
            return .loading(rowCount: order.lineItems.count + order.customAmounts.count)
        }

        return .loaded(
            lineItems: displayedLineItems,
            customAmounts: displayedCustomAmounts,
            refundedItems: order.refunds.flatMap(\.items)
        )
    }

    @MainActor
    var displayedLineItems: [POSOrderItem] {
        guard let order = selectedOrder else { return [] }
        guard !isLoadingOrderRefunds else {
            return order.lineItems
        }
        let refundedQuantities = order.refunds.flatMap(\.items).refundedQuantitiesByItemID()
        return order.lineItems.filter { item in
            let refunded = refundedQuantities[item.itemID] ?? 0
            return refunded < NSDecimalNumber(decimal: item.quantity).intValue
        }
    }

    /// Custom amounts to render in the order details items section, with already-refunded
    /// fees filtered out.
    ///
    /// The exclusion relies on the refund response carrying `fee_lines` whose `_refunded_item_id`
    /// meta points back to the original order's fee id. Stores on WooCommerce versions that
    /// omit `fee_lines` (or the meta) will fall through and the refunded fee will keep showing
    /// in this list — there is no other server-provided link from a refund back to the fee it
    /// refunded.
    @MainActor
    var displayedCustomAmounts: [POSOrderCustomAmount] {
        guard let order = selectedOrder else { return [] }
        guard !isLoadingOrderRefunds else {
            return order.customAmounts
        }
        let refundedItemIDs: Set<Int64> = Set(order.refunds.flatMap(\.items).compactMap(\.refundedItemID))
        return order.customAmounts.filter { !refundedItemIDs.contains($0.id) }
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
        if !fetchStrategy.showsCachedDataWhileLoading {
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
                selectedOrder = orderApplyingCachedRefunds(updatedSelectedOrder)
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
        selectedOrder = order.map(orderApplyingCachedRefunds)
        if let order, case .failed? = refundDetailsByOrderID[order.id] {
            // Allow the skeleton and a retry when returning to an order whose refund fetch failed.
            refundDetailsByOrderID[order.id] = nil
        }
        if let order, refundDetailsByOrderID[order.id] == nil, order.refunds.contains(where: { $0.items.isNotEmpty }) {
            // Persist refund details that arrived pre-loaded in the payload, so list refreshes,
            // which rebuild orders from summary data, don't re-show the skeleton and re-fetch.
            refundDetailsByOrderID[order.id] = .loaded(order.refunds)
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
        // Drop cached refund details — the refreshed order may have new refunds.
        refundDetailsByOrderID[orderID] = nil
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

    // MARK: - Refund Details

    @MainActor
    func loadOrderRefunds() async {
        guard let order = selectedOrder, order.refunds.isNotEmpty else {
            return
        }

        switch refundDetailsState(for: order) {
        case .loaded, .loading:
            return
        case .needsLoading, .failed:
            break
        }

        let orderID = order.id
        refundDetailsByOrderID[orderID] = .loading
        do {
            let refunds = try await refundsService.loadOrderRefunds(for: order)
            refundDetailsByOrderID[orderID] = .loaded(refunds)
            guard selectedOrder?.id == orderID else { return }
            selectedOrder = selectedOrder?.copy(refunds: .some(refunds))
        } catch {
            refundDetailsByOrderID[orderID] = .failed
            DDLogError("⛔️ Failed to load refund details: \(error)")
        }
    }

    @MainActor
    private func refundDetailsState(for order: POSOrder) -> POSOrderRefundDetailsState {
        guard order.refunds.isNotEmpty else {
            return .loaded([])
        }

        if let state = refundDetailsByOrderID[order.id] {
            return state
        }

        // Refund items are fetched together for the whole order, so any refund carrying items
        // means the details were already loaded (e.g. by another list entry for the same order).
        if order.refunds.contains(where: { $0.items.isNotEmpty }) {
            return .loaded(order.refunds)
        }

        return .needsLoading
    }

    @MainActor
    private func orderApplyingCachedRefunds(_ order: POSOrder) -> POSOrder {
        guard case .loaded(let refunds)? = refundDetailsByOrderID[order.id] else {
            return order
        }
        return order.copy(refunds: .some(refunds))
    }
}
