import Observation
import enum Yosemite.POSItem
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
        debugPrint("🍍 CouponsController::loadItems called")
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: .init(root: .loaded([], hasMoreItems: false), itemStates: [:]))
    }

    func refreshItems(base: ItemListBaseItem) async {
        await fetchItems()
    }

    func loadNextItems(base: ItemListBaseItem) async {
        debugPrint("🍍 CouponsController::loadNextItems called")
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: .init(root: .loaded([], hasMoreItems: false), itemStates: [:]))
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleCouponsController {
    func fetchItems() async {
        do {
            let items = try await itemProvider.providePointOfSaleItems(pageNumber: 1).items
            itemsViewState = ItemsViewState(containerState: .content,
                                            itemsStack: .init(root: .loaded(items, hasMoreItems: false),
                                                              itemStates: [:]))
        } catch {
            debugPrint(error)
        }
    }
}
