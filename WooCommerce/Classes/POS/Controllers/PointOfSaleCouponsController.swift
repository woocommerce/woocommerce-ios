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
        await fetchCoupons()
    }

    @MainActor
    func refreshItems(base: ItemListBaseItem) async {
        // TODO:
        // Handle unhappy path
        await fetchCoupons()
    }

    @MainActor
    func loadNextItems(base: ItemListBaseItem) async {
        // TODO:
        // Pagination WOOMOB-129
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                await fetchCoupons(pageNumber: pageNumber)
                return true
            }
        } catch {
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
    @MainActor
    func fetchCoupons(pageNumber: Int = Constants.firstPage) async {
        do {
            let pagedCoupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: pageNumber)
            let hasMoreItems = pagedCoupons.hasMorePages
            if pagedCoupons.items.isEmpty {
                setCouponsEmptyViewState()
            } else {
                setCouponsLoadedViewState(pagedCoupons.items, hasMoreItems: hasMoreItems)
            }
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError {
                setCouponsErrorViewState(couponError)
            }
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
        let containerState = ItemsContainerState.content
        let stackState: ItemsStackState

        switch couponError {
        case .couponsLoadingError:
            stackState = ItemsStackState(root: .error(.errorOnLoadingCoupons()), itemStates: [:])
        case .couponsDisabled:
            stackState = ItemsStackState(root: .error(.errorCouponsDisabled()), itemStates: [:])
        }

        itemsViewState = ItemsViewState(containerState: containerState, itemsStack: stackState)
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleCouponsController {
    enum Constants {
        static let firstPage: Int = 1
    }
}
