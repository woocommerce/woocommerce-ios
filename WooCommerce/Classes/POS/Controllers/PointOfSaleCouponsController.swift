import Observation
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleCouponServiceError
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol

@available(iOS 17.0, *)
@Observable final class PointOfSaleCouponsController: PointOfSaleCouponsControllerProtocol {
    var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
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
                return try await fetchCoupons(pageNumber: pageNumber, appendToExistingCoupons: false)
            }
        } catch {
            // TODO: Error handling
            debugPrint(error)
        }
    }

    @MainActor
    func enableCoupons() async {
        // TODO: WOOMOB-255
        // Handle loading state while coupons are being enabled
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
    func loadFirstPage() async {
        do {
            // 1. Attempt to load the first page from local storage, and present them
            let storedCoupons = try await couponProvider.provideLocalPointOfSaleCoupons()

            if !storedCoupons.isEmpty {
                setCouponsLoadedViewState(storedCoupons, hasMoreItems: true)
            } else {
                // 2. If there are no local results, retry again after syncing the first page from remote first
                let coupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: 1)
                if !coupons.items.isEmpty {
                    setCouponsLoadedViewState(coupons.items, hasMoreItems: true)
                } else {
                    setCouponsEmptyViewState()
                }
            }
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError {
                setCouponsErrorViewState(couponError)
            }
        }
    }

    @MainActor
    func fetchCoupons(pageNumber: Int, appendToExistingCoupons: Bool = true) async throws -> Bool {
        do {
            let pagedCoupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: pageNumber)

            let newCoupons = pagedCoupons.items
            var allCoupons = appendToExistingCoupons ? itemsViewState.itemsStack.root.items : []
            let uniqueNewCoupons = newCoupons.filter { newCoupon in
                !allCoupons.contains(newCoupon)
            }
            allCoupons.append(contentsOf: uniqueNewCoupons)

            let hasMoreItems = pagedCoupons.hasMorePages
            if pagedCoupons.items.isEmpty {
                setCouponsEmptyViewState()
            } else {
                setCouponsLoadedViewState(pagedCoupons.items, hasMoreItems: hasMoreItems)
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
        let stackState = ItemsStackState(root: .error(.errorCouponsNotFound()), itemStates: [:])
        itemsViewState = ItemsViewState(containerState: containerState, itemsStack: stackState)
    }

    func setCouponsLoadedViewState(_ coupons: [POSItem], hasMoreItems: Bool) {
        itemsViewState = ItemsViewState(containerState: .content,
                                        itemsStack: .init(root: .loaded(coupons, hasMoreItems: hasMoreItems),
                                                          itemStates: [:]))
    }

    func setCouponsErrorViewState(_ couponError: PointOfSaleCouponServiceError) {
        switch couponError {
        case .couponsLoadingError:
            itemsViewState = ItemsViewState(containerState: .error(.errorOnLoadingCoupons()),
                                            itemsStack: .init(root: .loaded([], hasMoreItems: false), itemStates: [:]))
        case .couponsDisabled:
            itemsViewState = ItemsViewState(containerState: .error(.errorCouponsDisabled()),
                                            itemsStack: .init(root: .loaded([], hasMoreItems: false), itemStates: [:]))
        }
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleCouponsController {
    enum Constants {
        static let firstPage: Int = 1
    }
}
