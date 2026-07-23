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

enum StartRefundFlowResult {
    case hasItemsToRefund
    case nothingToRefund
    case failed
}

protocol POSOrderListControllerProtocol {
    var ordersViewState: POSOrderListState { get }
    var selectedOrder: POSOrder? { get }
    var isLoadingOrderRefunds: Bool { get }
    var orderDetailsItemsState: POSOrderDetailsItemsState { get }
    var displayedLineItems: [POSOrderItem] { get }
    var displayedCustomAmounts: [POSOrderCustomAmount] { get }
    var refundActionAvailability: RefundActionAvailability { get }
    var refundSelectableItems: [POSRefundSelectableItem] { get }
    var currentRefundRequiresCardPresentRefund: Bool { get }
    var hasModifiedRefundSelection: Bool { get }
    func loadOrders() async
    func refreshOrders() async
    func loadNextOrders() async
    func selectOrder(_ order: POSOrder?)
    func updateOrder(orderID: Int64) async throws
    func preloadRefundDetails() async
    func startRefundFlow() async -> StartRefundFlowResult
    func toggleRefundItemSelection(at index: Int)
    func clearRefundSelection()
    func toggleAllRefundItemsSelection()
    var refundReviewPreparationState: POSRefundReviewPreparationState { get }
    func prepareRefundReview() async -> POSRefundReviewPreparationResult
    func processRefund(reason: String?) async throws
    func loadOrderRefunds() async
}

protocol POSSearchingOrderListControllerProtocol: POSOrderListControllerProtocol {
    func searchOrders(searchTerm: String) async
    func clearSearchOrders()
}

enum POSOrderListSelectedOrderRefundsState {
    case idle
    case loading
    case loaded(POSRefundPreparation)
    case failed(Error)
}

/// Observable UI state for the selection sheet while review preparation runs (button spinner and
/// inline preview error). The preparation's outcome is returned by `prepareRefundReview()` as a
/// `POSRefundReviewPreparationResult` instead of being published here.
enum POSRefundReviewPreparationState: Equatable {
    case idle
    case loading
    case previewError
}

/// Outcome of `prepareRefundReview()`, returned directly to the caller.
enum POSRefundReviewPreparationResult: Equatable {
    case ready(POSRefundReviewData)
    case previewError
    case preparationError
    /// A newer preparation or a selection change invalidated this one; callers ignore it.
    case superseded
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

enum RefundActionAvailability {
    case unknown
    case available
    case unavailable
}

enum POSRefundProcessingError: LocalizedError, Equatable {
    case missingSelectedOrder
    case missingRefundPreparation
    case emptySelection
    case refundAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .missingSelectedOrder, .missingRefundPreparation:
            return NSLocalizedString(
                "pos.refund.processing.error.missingPreparation",
                value: "The refund could not be prepared. Please try again.",
                comment: "Error shown when POS tries to process a refund without prepared order refund data."
            )
        case .emptySelection:
            return NSLocalizedString(
                "pos.refund.processing.error.emptySelection",
                value: "Select at least one item to refund.",
                comment: "Error shown when POS tries to process a refund without selected refund items."
            )
        case .refundAlreadyInProgress:
            return NSLocalizedString(
                "pos.refund.processing.error.alreadyInProgress",
                value: "A refund is already in progress. Please wait for it to finish.",
                comment: "Error shown when POS tries to process a second refund while another refund is in progress."
            )
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
    private(set) var selectedOrderRefundsState: POSOrderListSelectedOrderRefundsState = .idle
    private(set) var refundSelectableItems: [POSRefundSelectableItem] = []
    private(set) var hasModifiedRefundSelection = false
    private(set) var refundReviewPreparationState: POSRefundReviewPreparationState = .idle
    private var refundReviewPreparationTask: Task<POSRefundReviewPreparationResult, Never>?
    private let orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol
    private let refundsService: POSRefundsServiceProtocol
    private let refundSubmissionProcessor: POSRefundSubmissionProcessing
    private var isProcessingRefund = false
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
         refundSubmissionProcessor: POSRefundSubmissionProcessing,
         initialState: POSOrderListState = .loading([])) {
        self.ordersViewState = initialState
        self.orderListFetchStrategyFactory = orderListFetchStrategyFactory
        self.fetchStrategy = orderListFetchStrategyFactory.defaultStrategy()
        self.refundsService = refundsService
        self.refundSubmissionProcessor = refundSubmissionProcessor
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
    var refundActionAvailability: RefundActionAvailability {
        guard let order = selectedOrder,
              order.status == .completed else {
            return .unavailable
        }
        return .available
    }

    @MainActor
    var currentRefundRequiresCardPresentRefund: Bool {
        guard case .loaded(let preparation) = selectedOrderRefundsState else {
            return false
        }
        return preparation.requiresCardPresentRefund
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
        selectedOrderRefundsState = .idle
        refundSelectableItems = []
        hasModifiedRefundSelection = false
        resetRefundReviewPreparation()
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

    // MARK: - Refund Item Selection

    @MainActor
    func preloadRefundDetails() async {
        guard refundActionAvailability == .available,
              let order = selectedOrder else {
            return
        }
        await refundSubmissionProcessor.preloadRefund(for: order)
    }

    @MainActor
    func startRefundFlow() async -> StartRefundFlowResult {
        guard let order = selectedOrder else { return .failed }

        let preparation: POSRefundPreparation
        do {
            preparation = try await refundSubmissionProcessor.prepareRefund(for: order)
            selectedOrderRefundsState = .loaded(preparation)
        } catch {
            selectedOrderRefundsState = .failed(error)
            return .failed
        }

        refundSelectableItems = preparation.selectableItems
        hasModifiedRefundSelection = false
        resetRefundReviewPreparation()

        return refundSelectableItems.isEmpty ? .nothingToRefund : .hasItemsToRefund
    }


    @MainActor
    func toggleRefundItemSelection(at index: Int) {
        guard refundSelectableItems.indices.contains(index) else { return }
        refundSelectableItems[index].isSelected.toggle()
        hasModifiedRefundSelection = true
        resetRefundReviewPreparation()
    }

    @MainActor
    func clearRefundSelection() {
        refundSelectableItems = []
        hasModifiedRefundSelection = false
        resetRefundReviewPreparation()
    }

    @MainActor
    func toggleAllRefundItemsSelection() {
        guard !refundSelectableItems.isEmpty else { return }
        let allSelected = !refundSelectableItems.isEmpty && refundSelectableItems.allSatisfy { $0.isSelected }
        let newSelectionState = !allSelected
        for index in refundSelectableItems.indices {
            refundSelectableItems[index].isSelected = newSelectionState
        }
        hasModifiedRefundSelection = true
        resetRefundReviewPreparation()
    }

    // MARK: - Refund Review Data Preparation

    @MainActor
    func prepareRefundReview() async -> POSRefundReviewPreparationResult {
        refundReviewPreparationTask?.cancel()

        guard let order = selectedOrder,
              case .loaded(let preparation) = selectedOrderRefundsState else {
            refundReviewPreparationState = .idle
            return .preparationError
        }

        let selectedItems = refundSelectableItems.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            refundReviewPreparationState = .idle
            return .preparationError
        }

        let selectionSnapshot = refundSelectableItems
        refundReviewPreparationState = .loading
        let preparationTask = Task { @MainActor [weak self] () -> POSRefundReviewPreparationResult in
            guard let self else { return .superseded }
            do {
                let reviewData = try await refundSubmissionProcessor.prepareReviewData(
                    for: order,
                    preparation: preparation,
                    selectedItems: selectedItems,
                    reason: nil
                )
                guard !Task.isCancelled, refundSelectableItems == selectionSnapshot else { return .superseded }
                refundReviewPreparationState = .idle
                return .ready(reviewData)
            } catch is CancellationError {
                return .superseded
            } catch POSRefundSubmissionError.refundPreviewFailed {
                guard !Task.isCancelled, refundSelectableItems == selectionSnapshot else { return .superseded }
                refundReviewPreparationState = .previewError
                return .previewError
            } catch {
                guard !Task.isCancelled, refundSelectableItems == selectionSnapshot else { return .superseded }
                refundReviewPreparationState = .idle
                return .preparationError
            }
        }
        refundReviewPreparationTask = preparationTask
        return await preparationTask.value
    }

    @MainActor
    func resetRefundReviewPreparation() {
        refundReviewPreparationTask?.cancel()
        refundReviewPreparationTask = nil
        refundReviewPreparationState = .idle
    }

    // MARK: - Refund Processing

    @MainActor
    func processRefund(reason: String?) async throws {
        guard !isProcessingRefund else {
            throw POSRefundProcessingError.refundAlreadyInProgress
        }

        isProcessingRefund = true
        defer {
            isProcessingRefund = false
        }

        guard let order = selectedOrder else {
            throw POSRefundProcessingError.missingSelectedOrder
        }

        guard case .loaded(let preparation) = selectedOrderRefundsState else {
            throw POSRefundProcessingError.missingRefundPreparation
        }

        let selectedItems = refundSelectableItems.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            throw POSRefundProcessingError.emptySelection
        }

        try await refundSubmissionProcessor.submitRefund(
            for: order,
            preparation: preparation,
            selectedItems: selectedItems,
            reason: reason
        )

        clearRefundSelection()
        try? await updateOrder(orderID: order.id)
        await loadOrderRefunds()
    }

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
