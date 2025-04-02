import Observation
import enum Yosemite.POSItem
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
        // Handle unhappy path
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
}

@available(iOS 17.0, *)
private extension PointOfSaleCouponsController {
    @MainActor
    func loadFirstPage() async {
        // WIP
        let containerState = ItemsContainerState.content
        let stackState = ItemsStackState(root: .inlineError([], error: .errorCouponsNotFound()), itemStates: [:])
        itemsViewState = ItemsViewState(containerState: containerState, itemsStack: stackState)
        return
        do {
            let coupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: 1).items
            itemsViewState = ItemsViewState(containerState: .content,
                                            itemsStack: .init(root: .loaded(coupons, hasMoreItems: false),
                                                              itemStates: [:]))
        } catch {
            debugPrint(error)
        }
    }
}
