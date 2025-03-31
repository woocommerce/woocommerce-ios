import Observation
import enum Yosemite.POSItem
import enum Yosemite.CouponAction
import protocol Yosemite.PointOfSaleItemServiceProtocol

@available(iOS 17.0, *)
@Observable final class PointOfSaleCouponsController: PointOfSaleItemsControllerProtocol {
    var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
                                                        itemsStack: ItemsStackState(root: .loading([]),
                                                                                    itemStates: [:]))
    private let paginationTracker: AsyncPaginationTracker
    private var childPaginationTrackers: [POSItem: AsyncPaginationTracker] = [:]
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
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
        do {
            let coupons = try await itemProvider.providePointOfSaleItems(pageNumber: 1).items
            itemsViewState = ItemsViewState(containerState: .content,
                                            itemsStack: .init(root: .loaded(coupons, hasMoreItems: false),
                                                              itemStates: [:]))

            await syncCoupons()
        } catch {
            debugPrint(error)
        }
    }

    @MainActor
    func syncCoupons() async {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }
        let action = CouponAction.synchronizeCoupons(siteID: siteID,
                                                     pageNumber: 1,
                                                     pageSize: 25,
                                                     onCompletion: { _ in })
        ServiceLocator.stores.dispatch(action)
    }
}
