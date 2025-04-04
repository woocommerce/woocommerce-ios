import Observation
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleCouponServiceError
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol

@available(iOS 17.0, *)
@Observable final class PointOfSaleCouponsController: PointOfSaleItemsControllerProtocol {
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
        // TODO:
        // Pagination https://github.com/woocommerce/woocommerce-ios/issues/15343
        await loadFirstPage()
    }

    @MainActor
    func enableCoupons() async {
        // TODO: WOOMOB-255
        // Handle loading state while coupons are being enabled, or error.
        await couponProvider.enableCoupons()
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleCouponsController {
    @MainActor
    func loadFirstPage() async {
        do {
            let coupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: 1).items
            if coupons.isEmpty {
                let containerState = ItemsContainerState.content
                let stackState = ItemsStackState(root: .error(.errorCouponsNotFound()), itemStates: [:])
                itemsViewState = ItemsViewState(containerState: containerState, itemsStack: stackState)
            } else {
                itemsViewState = ItemsViewState(containerState: .content,
                                                itemsStack: .init(root: .loaded(coupons, hasMoreItems: false),
                                                                  itemStates: [:]))
            }
        } catch {
            if let couponError = error as? PointOfSaleCouponServiceError {
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
    }
}
