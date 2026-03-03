import Observation
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleCouponServiceError
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponFetchStrategyFactoryProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol
import struct Yosemite.PointOfSaleCouponFetchStrategyFactory
import protocol Yosemite.PointOfSaleCouponFetchStrategy
import class Yosemite.AsyncPaginationTracker
import enum Yosemite.SearchDebounceStrategy

protocol PointOfSaleCouponsControllerProtocol: PointOfSaleSearchingItemsControllerProtocol {
    /// Enables coupons in store settings
    /// Returns true if coupons enabled
    func enableCoupons() async
}

@Observable final class PointOfSaleCouponsController: PointOfSaleCouponsControllerProtocol {
    var itemsViewState: ItemsViewState = ItemsViewState(containerState: .content,
                                                        itemsStack: ItemsStackState(root: .loading([]),
                                                                                    itemStates: [:]))
    private let paginationTracker: AsyncPaginationTracker
    private var childPaginationTrackers: [POSItem: AsyncPaginationTracker] = [:]
    private let couponProvider: PointOfSaleCouponServiceProtocol
    private let fetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryProtocol
    private var fetchStrategy: PointOfSaleCouponFetchStrategy
    private let analyticsProvider: POSAnalyticsProviding

    init(itemProvider: PointOfSaleCouponServiceProtocol,
         fetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryProtocol,
         analyticsProvider: POSAnalyticsProviding) {
        self.couponProvider = itemProvider
        self.fetchStrategyFactory = fetchStrategyFactory
        self.fetchStrategy = fetchStrategyFactory.defaultStrategy
        self.paginationTracker = .init()
        self.analyticsProvider = analyticsProvider
    }

    @MainActor
    func loadItems(base: ItemListBaseItem) async {
        await loadFirstPage()
    }

    @MainActor
    func refreshItems(base: ItemListBaseItem) async {
        await loadFirstPageRemotely()
    }

    @MainActor
    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async {
        fetchStrategy = fetchStrategyFactory.searchStrategy(searchTerm: searchTerm,
                                                            analytics: POSItemFetchAnalytics(itemType: .coupon, analytics: analyticsProvider))
        setSearchingState()
        await loadFirstPage()
    }

    func clearSearchItems(baseItem: ItemListBaseItem) {
        setSearchingState()
    }

    var currentDebounceStrategy: SearchDebounceStrategy {
        fetchStrategy.debounceStrategy
    }

    var searchDebounceStrategy: SearchDebounceStrategy {
        // Return the debounce strategy that would be used for a search
        let searchStrategy = fetchStrategyFactory.searchStrategy(searchTerm: "",
                                                                 analytics: POSItemFetchAnalytics(itemType: .coupon,
                                                                                                  analytics: analyticsProvider))
        return searchStrategy.debounceStrategy
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
            let underlyingError = (error as? PointOfSaleCouponServiceError)?.underlyingError
            itemsViewState.containerState = .content
            itemsViewState.itemsStack = ItemsStackState(root: .inlineError(currentItems,
                                                                           error: .errorOnLoadingCouponsNextPage(error: underlyingError),
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
}

private extension PointOfSaleCouponsController {
    /// Loads the first page by attempting to load the first page from local storage
    /// then syncs from the remote regardless the result
    func loadFirstPage() async {
        do {
            let storedCoupons = try await couponProvider.provideLocalPointOfSaleCoupons(fetchStrategy: fetchStrategy)
            if !storedCoupons.isEmpty {
                setCouponsLoadedViewState(storedCoupons, hasMoreItems: true)
            }
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError,
               couponError == .couponsDisabled {
                setCouponsErrorViewState(error)
                return
            }
        }
        await loadFirstPageRemotely()
    }

    func loadFirstPageRemotely() async {
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchCoupons(pageNumber: pageNumber)
            }
        } catch {
            setCouponsErrorViewState(error)
        }
    }

    @MainActor
    func fetchCoupons(pageNumber: Int) async throws -> Bool {
        let pagedCoupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: pageNumber, fetchStrategy: fetchStrategy)

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
private extension PointOfSaleCouponsController {
    func setSearchingState() {
        itemsViewState.itemsStack.root = .loading([])
    }

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

    func setCouponsErrorViewState(_ error: Error) {
        guard let couponError = error as? PointOfSaleCouponServiceError else {
            itemsViewState.itemsStack = ItemsStackState(root: .error(.errorOnLoadingCoupons(error: error)), itemStates: [:])
            return
        }

        switch couponError {
        case .couponsLoadingError(let underlyingError):
            let items = itemsViewState.itemsStack.root.items
            if items.isEmpty {
                itemsViewState.itemsStack = ItemsStackState(root: .error(.errorOnLoadingCoupons(error: underlyingError)), itemStates: [:])
            } else {
                itemsViewState.itemsStack = ItemsStackState(
                    root: .inlineError(items, error: .errorOnRefreshingCoupons(error: underlyingError), context: .refresh), itemStates: [:]
                )
            }
        case .couponsDisabled:
            itemsViewState.itemsStack = ItemsStackState(root: .error(.errorCouponsDisabled), itemStates: [:])
        case .couponsEnablingError(let underlyingError):
            itemsViewState.itemsStack = ItemsStackState(root: .error(.errorOnEnablingCoupons(error: underlyingError)), itemStates: [:])
        case .requestCancelled:
            break
        }
    }
}
