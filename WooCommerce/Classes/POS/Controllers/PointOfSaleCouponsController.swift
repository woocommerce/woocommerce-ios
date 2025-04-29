import Observation
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleCouponServiceError
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol

@available(iOS 17.0, *)
protocol PointOfSaleSearchingCouponsControllerProtocol: PointOfSaleItemsControllerProtocol {
    /// Searches for coupons
    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async
}

@available(iOS 17.0, *)
protocol PointOfSaleCouponsControllerProtocol: PointOfSaleItemsControllerProtocol {
    /// Enables coupons in store settings
    /// Returns true if coupons enabled
    func enableCoupons() async
}

@available(iOS 17.0, *)
@Observable final class PointOfSaleCouponsController: PointOfSaleCouponsControllerProtocol {
    var itemsViewState: ItemsViewState = ItemsViewState(containerState: .content,
                                                        itemsStack: ItemsStackState(root: .loading([]),
                                                                                    itemStates: [:]))
    private let paginationTracker: AsyncPaginationTracker
    private var childPaginationTrackers: [POSItem: AsyncPaginationTracker] = [:]
    private let couponProvider: PointOfSaleCouponServiceProtocol

    init(itemProvider: PointOfSaleCouponServiceProtocol) {
        self.couponProvider = itemProvider
        self.paginationTracker = .init()
    }

    @MainActor
    func loadItems(base: ItemListBaseItem) async {
        await loadFirstPage()
    }

    @MainActor
    func refreshItems(base: ItemListBaseItem) async {
        await loadFirstPage()
    }

    @MainActor
    func loadNextItems(base: ItemListBaseItem) async {
        guard paginationTracker.hasNextPage else {
            return
        }

        let currentItems = itemsViewState.itemsStack.root.items
        let currentItemStates = itemsViewState.itemsStack.itemStates
        itemsViewState.containerState = .content
        itemsViewState.itemsStack = ItemsStackState(root: .loading(currentItems),
                                                   itemStates: currentItemStates)

        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchCoupons(pageNumber: pageNumber)
            }
        } catch {
            itemsViewState.containerState = .content
            itemsViewState.itemsStack = ItemsStackState(root: .inlineError(currentItems,
                                                                           error: .errorOnLoadingCouponsNextPage,
                                                                           context: .pagination),
                                                        itemStates: currentItemStates)
        }
    }

    @MainActor
    func enableCoupons() async {
        itemsViewState.itemsStack.root = .loading([])
        do {
            try await couponProvider.enableCoupons()
            await loadItems(base: .root)
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError {
                setCouponsErrorViewState(couponError)
            }
        }
    }

    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async {
        // TODO: Pass fetching strategy
        await loadFirstPage()
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleCouponsController {
    /// Loads the first page by attempting to load the first page from local storage
    /// then syncs from the remote regardless the result
    func loadFirstPage() async {
        do {
            let storedCoupons = try await couponProvider.provideLocalPointOfSaleCoupons()
            if !storedCoupons.isEmpty {
                setCouponsLoadedViewState(storedCoupons, hasMoreItems: true)
            }

            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchCoupons(pageNumber: pageNumber)
            }
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError {
                setCouponsErrorViewState(couponError)
            }
        }
    }

    @MainActor
    func fetchCoupons(pageNumber: Int) async throws -> Bool {
        let pagedCoupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: pageNumber)

        let allCoupons = pagedCoupons.items
        let hasMoreItems = pagedCoupons.hasMorePages

        if allCoupons.isEmpty {
            setCouponsEmptyViewState()
        } else {
            setCouponsLoadedViewState(allCoupons, hasMoreItems: hasMoreItems)
        }
        return pagedCoupons.hasMorePages
    }
}

// MARK: - View state helpers
//
@available(iOS 17.0, *)
private extension PointOfSaleCouponsController {
    func setCouponsEmptyViewState() {
        let containerState = ItemsContainerState.content
        let stackState = ItemsStackState(root: .empty, itemStates: [:])
        itemsViewState = ItemsViewState(containerState: containerState, itemsStack: stackState)
    }

    func setCouponsLoadedViewState(_ coupons: [POSItem], hasMoreItems: Bool) {
        itemsViewState = ItemsViewState(containerState: .content,
                                        itemsStack: .init(root: .loaded(coupons, hasMoreItems: hasMoreItems),
                                                          itemStates: [:]))
    }

    func setCouponsErrorViewState(_ couponError: PointOfSaleCouponServiceError) {
        let containerState = ItemsContainerState.content
        let stackState: ItemsStackState

        switch couponError {
        case .couponsLoadingError:
            let items = itemsViewState.itemsStack.root.items
            if items.isEmpty {
                stackState = ItemsStackState(root: .error(.errorOnLoadingCoupons), itemStates: [:])
            } else {
                stackState = ItemsStackState(root: .inlineError(items, error: .errorOnRefreshingCoupons, context: .refresh), itemStates: [:])
            }
        case .couponsDisabled:
            stackState = ItemsStackState(root: .error(.errorCouponsDisabled), itemStates: [:])
        case .couponsEnablingError:
            stackState = ItemsStackState(root: .error(.errorOnEnablingCoupons), itemStates: [:])
        }

        itemsViewState = ItemsViewState(containerState: containerState, itemsStack: stackState)
    }
}
