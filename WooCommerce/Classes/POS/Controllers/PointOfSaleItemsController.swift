import Foundation
import Combine
import enum Yosemite.POSItem
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.PointOfSaleProductServiceError

protocol PointOfSaleItemsControllerProtocol {
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    private(set) var itemsViewStatePublisher: any Publisher<ItemsViewState, Never>
    private var itemsViewStateSubject: PassthroughSubject<ItemsViewState, Never> = .init()
    private var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
                                                                itemsStack: ItemsStackState(root: .loading([]))) {
        didSet {
            itemsViewStateSubject.send(itemsViewState)
        }
    }
    private let paginationTracker: AsyncPaginationTracker
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
        self.paginationTracker = .init()
        itemsViewStatePublisher = itemsViewStateSubject.eraseToAnyPublisher()
    }

    @MainActor
    func loadInitialItems() async {
        itemsViewState = ItemsViewState(containerState: .loading, itemsStack: ItemsStackState(root: .loading([])))
        do {
            try await paginationTracker.syncFirstPage { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
        } catch {
            itemsViewState = ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                            itemsStack: ItemsStackState(root: .loaded([])))
        }
    }

    @MainActor
    func loadNextItems() async {
        guard paginationTracker.hasNextPage else {
            return
        }
        let currentItems = itemsViewState.itemsStack.root.items
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loading(currentItems)))
        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
        } catch {
            // TODO: 14694 - Handle error from loading the next page, like showing an error UI at the end or as an overlay.
            itemsViewState = ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                            itemsStack: ItemsStackState(root: .loaded(currentItems)))
        }
    }

    @MainActor
    func reload() async {
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber, appendToExistingItems: false)
            }
        } catch {
            // TODO: 14694 - Handle error from pull-to-refresh, like showing an error UI at the beginning or as an overlay.
            itemsViewState = ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                            itemsStack: ItemsStackState(root: .loaded([])))
        }
    }

    /// Fetches items given a page number and appends new unique items to the `allItems` array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Parameter appendToExistingItems: Default true – set this to false when refreshing to make the new page the only page.
    /// - Returns: A boolean that indicates whether there is next page for the paginated items.
    @MainActor
    private func fetchItems(pageNumber: Int, appendToExistingItems: Bool = true) async throws -> Bool {
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let newItems = pagedItems.items
        var allItems = appendToExistingItems ? itemsViewState.itemsStack.root.items : []
        let uniqueNewItems = newItems.filter { newItem in
            // Note that this uniquing won't currently work, as POSItem has a UUID.
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)
        if allItems.isEmpty {
            itemsViewState = ItemsViewState(containerState: .empty,
                                            itemsStack: ItemsStackState(root: .loaded([])))
        } else {
            itemsViewState = ItemsViewState(containerState: .content,
                                            itemsStack: ItemsStackState(root: .loaded(allItems)))
        }
        return pagedItems.hasMorePages
    }
}

private extension ItemListState {
    var items: [POSItem] {
        switch self {
        case .loading(let items),
                .loaded(let items):
            return items
        case .error:
            return []
        }
    }
}
