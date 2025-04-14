import Observation
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleCouponServiceError
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol

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
        // TODO:
        // Handle unhappy path:
        // Depending on the error type (failed to load vs coupons disabled) we want to show a different CTA choice
        await loadFirstPage()
    }

    @MainActor
    func refreshItems(base: ItemListBaseItem) async {
        // TODO:
        // Handle unhappy path
        await loadFirstPage()
    }

    @MainActor
    func loadNextItems(base: ItemListBaseItem) async {
        guard paginationTracker.hasNextPage else {
            return
        }

        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchCoupons(pageNumber: pageNumber)
            }
        } catch {
            // TODO: Error handling
            debugPrint(error)
        }
    }

    @MainActor
    func enableCoupons() async {
        itemsViewState.itemsStack.root = .loading([])
        do {
            try await couponProvider.enableCoupons()
        } catch {
            // TODO: WOOMOB-267
            // Handle error when failed to enable, and allow retry action
            debugPrint(error)
        }
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
            _ = try await fetchCoupons(pageNumber: 1)
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError {
                setCouponsErrorViewState(couponError)
            }
        }
    }

    @MainActor
    func fetchCoupons(pageNumber: Int) async throws -> Bool {
        do {
            let pagedCoupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: pageNumber)

            let allCoupons = pagedCoupons.items
            let hasMoreItems = pagedCoupons.hasMorePages

            if allCoupons.isEmpty {
                setCouponsEmptyViewState()
            } else {
                setCouponsLoadedViewState(allCoupons, hasMoreItems: hasMoreItems)
            }
            return pagedCoupons.hasMorePages
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError {
                setCouponsErrorViewState(couponError)
            }
            return true
        }
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
            stackState = ItemsStackState(root: .error(.errorOnLoadingCoupons), itemStates: [:])
        case .couponsDisabled:
            stackState = ItemsStackState(root: .error(.errorCouponsDisabled), itemStates: [:])
        }

        itemsViewState = ItemsViewState(containerState: containerState, itemsStack: stackState)
    }
}
