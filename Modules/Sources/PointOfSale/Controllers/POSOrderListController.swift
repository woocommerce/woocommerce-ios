import Foundation
import Observation
import enum Yosemite.POSOrderListServiceError
import protocol Yosemite.POSOrderListServiceProtocol
import protocol Yosemite.POSOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.POSOrderListFetchStrategy
import protocol Yosemite.POSRefundsServiceProtocol
import struct Yosemite.POSOrder
import struct Yosemite.POSRefund
import struct Yosemite.POSRefundItem
import struct Yosemite.POSRefundsResult
import struct Yosemite.POSRefundableItem
import struct Yosemite.POSRefundAmounts
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderCustomAmount
import struct Yosemite.POSOrderRefund
import class Yosemite.Store
import class Yosemite.AsyncPaginationTracker
import protocol Experiments.FeatureFlagService
import class WooFoundation.CurrencyFormatter
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
    var displayedLineItems: [POSOrderItem] { get }
    var displayedCustomAmounts: [POSOrderCustomAmount] { get }
    var refundActionAvailability: RefundActionAvailability { get }
    var refundSelectableItems: [POSRefundSelectableItem] { get }
    func loadOrders() async
    func refreshOrders() async
    func loadNextOrders() async
    func selectOrder(_ order: POSOrder?)
    func updateOrder(orderID: Int64) async throws
    func startRefundFlow() async -> StartRefundFlowResult
    func toggleRefundItemSelection(at index: Int)
    func clearRefundSelection()
    func toggleAllRefundItemsSelection()
    func preparePOSRefundReviewData() -> POSRefundReviewData?
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
    case loaded(POSRefundsResult)
    case failed(Error)
}

enum RefundActionAvailability {
    case unknown
    case available
    case unavailable
}

@Observable final class POSOrderListController: POSSearchingOrderListControllerProtocol {
    var ordersViewState: POSOrderListState
    private var strategyPaginationTracker: [String: AsyncPaginationTracker] = [:]
    private var fetchStrategy: POSOrderListFetchStrategy
    private var cachedOrders: [POSOrder] = []
    private(set) var selectedOrder: POSOrder?
    private(set) var isLoadingOrderRefunds = false
    private(set) var selectedOrderRefundsState: POSOrderListSelectedOrderRefundsState = .idle
    private(set) var refundSelectableItems: [POSRefundSelectableItem] = []
    private let orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol
    private let refundsService: POSRefundsServiceProtocol
    private let featureFlags: POSFeatureFlagProviding
    private let currencySettingsProvider: POSCurrencySettingsProviding
    private let currencyFormatter: CurrencyFormatter
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
         currencySettingsProvider: POSCurrencySettingsProviding,
         currencyFormatter: CurrencyFormatter,
         initialState: POSOrderListState = .loading([])) {
        self.ordersViewState = initialState
        self.orderListFetchStrategyFactory = orderListFetchStrategyFactory
        self.fetchStrategy = orderListFetchStrategyFactory.defaultStrategy()
        self.refundsService = refundsService
        self.featureFlags = featureFlags
        self.currencySettingsProvider = currencySettingsProvider
        self.currencyFormatter = currencyFormatter
    }

    @MainActor
    var refundActionAvailability: RefundActionAvailability {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRefundsi1),
              let order = selectedOrder,
              order.status == .completed else {
            return .unavailable
        }
        return .available
    }

    @MainActor
    var displayedLineItems: [POSOrderItem] {
        guard let order = selectedOrder else { return [] }
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRefundsi1),
              !isLoadingOrderRefunds else {
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
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRefundsi1),
              !isLoadingOrderRefunds else {
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
        isLoadingOrderRefunds = false
        selectedOrderRefundsState = .idle
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

    // MARK: - Refund Item Selection

    @MainActor
    func startRefundFlow() async -> StartRefundFlowResult {
        guard let order = selectedOrder else { return .failed }

        // Fetch refunds from API
        let refundsResult: POSRefundsResult
        do {
            refundsResult = try await refundsService.providePointOfSaleRefunds(for: order)
            selectedOrderRefundsState = .loaded(refundsResult)
        } catch {
            selectedOrderRefundsState = .failed(error)
            return .failed
        }

        // Calculate already refunded quantities per itemID
        let refundedQuantitiesByItemID = refundsResult.refunds.flatMap(\.items).refundedQuantitiesByItemID()

        // Build selectable items excluding already refunded quantities
        let productSelectables = order.lineItems.flatMap { item -> [POSRefundSelectableItem] in
            let originalQuantity = NSDecimalNumber(decimal: item.quantity).intValue
            let refundedQuantity = refundedQuantitiesByItemID[item.itemID] ?? 0
            let availableQuantity = originalQuantity - refundedQuantity
            guard availableQuantity > 0 else { return [] }

            return (0..<availableQuantity).map { index in
                POSRefundSelectableItem(from: item, isSelected: true, index: index)
            }
        }

        let alreadyRefundedItemIDs: Set<Int64> = Set(
            refundsResult.refunds
                .flatMap(\.items)
                .compactMap(\.refundedItemID)
        )
        let feeSelectables = order.customAmounts
            .filter { !alreadyRefundedItemIDs.contains($0.id) }
            .map { POSRefundSelectableItem(from: $0, isSelected: true) }

        refundSelectableItems = productSelectables + feeSelectables

        return refundSelectableItems.isEmpty ? .nothingToRefund : .hasItemsToRefund
    }


    @MainActor
    func toggleRefundItemSelection(at index: Int) {
        guard refundSelectableItems.indices.contains(index) else { return }
        refundSelectableItems[index].isSelected.toggle()
    }

    @MainActor
    func clearRefundSelection() {
        refundSelectableItems = []
    }

    @MainActor
    func toggleAllRefundItemsSelection() {
        let allSelected = !refundSelectableItems.isEmpty && refundSelectableItems.allSatisfy { $0.isSelected }
        let newSelectionState = !allSelected
        for index in refundSelectableItems.indices {
            refundSelectableItems[index].isSelected = newSelectionState
        }
    }

    // MARK: - Refund Review Data Preparation

    @MainActor
    func preparePOSRefundReviewData() -> POSRefundReviewData? {
        guard let order = selectedOrder else { return nil }

        let selectedItems = refundSelectableItems.filter { $0.isSelected }
        guard !selectedItems.isEmpty else { return nil }

        let refundableItems = selectedItems.map { item in
            POSRefundableItem(
                itemID: item.itemID,
                lineItemTotal: item.lineItemTotal,
                totalTax: item.totalTax,
                originalQuantity: item.originalQuantity,
                isLumpSum: item.isLumpSum
            )
        }

        let amounts = refundsService.calculateRefundAmounts(for: refundableItems)

        guard let formattedSubtotal = currencyFormatter.formatAmount(amounts.subtotal),
              let formattedTax = currencyFormatter.formatAmount(amounts.tax),
              let formattedTotal = currencyFormatter.formatAmount(amounts.total) else {
            return nil
        }

        let paymentMethodDescription = createPaymentMethodDescription(for: order)

        return POSRefundReviewData(
            itemsCount: selectedItems.count,
            formattedItemsSubtotal: formattedSubtotal,
            formattedTax: formattedTax,
            formattedRefundTotal: formattedTotal,
            paymentMethodDescription: paymentMethodDescription,
            customerEmail: order.customerEmail,
            refundReason: nil,
            isFullRefund: selectedItems.count == refundSelectableItems.count
        )
    }

    private func createPaymentMethodDescription(for order: POSOrder) -> String {
        String(format: Localization.viaPaymentMethodFormat, order.paymentMethodTitle)
    }

    // MARK: - Refund Processing

    @MainActor
    func processRefund(reason: String?) async throws {
        guard let order = selectedOrder else {
            assertionFailure("processRefund called without selected order")
            return
        }

        guard case .loaded(let refundsResult) = selectedOrderRefundsState else {
            assertionFailure("processRefund called without loaded refunds state")
            return
        }

        let selectedItems = refundSelectableItems.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            assertionFailure("processRefund called without selected items")
            return
        }

        let refundableItems = selectedItems.map { item in
            POSRefundableItem(
                itemID: item.itemID,
                lineItemTotal: item.lineItemTotal,
                totalTax: item.totalTax,
                originalQuantity: item.originalQuantity,
                isLumpSum: item.isLumpSum
            )
        }

        try await refundsService.createRefund(
            orderID: order.id,
            items: refundableItems,
            reason: reason,
            isAutomaticRefund: refundsResult.supportsAutomaticRefund
        )

        clearRefundSelection()
        try? await updateOrder(orderID: order.id)
        await loadOrderRefunds()
    }

    func loadOrderRefunds() async {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRefundsi1) else { return }
        guard let order = selectedOrder, order.refunds.isNotEmpty else {
            return
        }
        isLoadingOrderRefunds = true
        do {
            let refunds = try await refundsService.loadOrderRefunds(for: order)
            guard selectedOrder?.id == order.id else { return }
            selectedOrder = order.copy(refunds: .some(refunds))
        } catch {
            DDLogError("⛔️ Failed to load refund details: \(error)")
        }
        isLoadingOrderRefunds = false
    }
}

// MARK: - Localization

private extension POSOrderListController {
    enum Localization {
        static let viaPaymentMethodFormat = NSLocalizedString(
            "pos.orderListController.refund.viaPaymentMethodFormat",
            value: "Via %@",
            comment: "Description for refund via a specific payment method. %@ is the payment method name"
        )
    }
}
