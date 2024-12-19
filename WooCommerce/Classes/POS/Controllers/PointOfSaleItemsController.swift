import Foundation
import Combine
import enum Yosemite.POSItem
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.PointOfSaleProductServiceError

protocol PointOfSaleItemsControllerProtocol {
    var itemListStatePublisher: any Publisher<ItemListState, Never> { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    private(set) var itemListStatePublisher: any Publisher<ItemListState, Never>
    private var itemListStateSubject: PassthroughSubject<ItemListState, Never> = .init()
    private var allItems: [POSItem] = []
    private var reloadTask: Task<Void, Never>?
    private let paginationTracker: AsyncPaginationTracker
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
        self.paginationTracker = .init()
        itemListStatePublisher = itemListStateSubject.eraseToAnyPublisher()
    }

    @MainActor
    func loadInitialItems() async {
        itemListStateSubject.send(.initialLoading)
        do {
            try await paginationTracker.syncFirstPage { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
            updateItemListStateAfterLoadAttempt()
        } catch {
            itemListStateSubject.send(.error(PointOfSaleErrorState.errorOnLoadingProducts()))
        }
    }

    @MainActor
    func loadNextItems() async {
        itemListStateSubject.send(.loading(allItems))
        do {
            let nextPageState = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
            switch nextPageState {
                case .noNextPage, .synced:
                    updateItemListStateAfterLoadAttempt()
                case .syncing:
                    break
            }
        } catch {
            // TODO: 14694 - Handle error from loading the next page, like showing an error UI at the end or as an overlay.
            itemListStateSubject.send(.error(PointOfSaleErrorState.errorOnLoadingProducts()))
        }
    }

    @MainActor
    func reload() async {
        // Reload is invoked when pulling to refresh as the SwiftUI `refreshable` async action, and it is canceled when the refresh
        // control is released. Using a separate task ensures the reload async task is not canceled when the refresh control is released.
        reloadTask?.cancel()
        reloadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            allItems.removeAll()
            itemListStateSubject.send(.loading(allItems))
            do {
                try await paginationTracker.resync { [weak self] pageNumber in
                    guard let self else { return true }
                    return try await fetchItems(pageNumber: pageNumber)
                }
                updateItemListStateAfterLoadAttempt()
            } catch {
                // TODO: 14694 - Handle error from pull-to-refresh, like showing an error UI at the beginning or as an overlay.
                itemListStateSubject.send(.error(PointOfSaleErrorState.errorOnLoadingProducts()))
            }
        }
    }

    /// Fetches items given a page number and appends new unique items to the `allItems` array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Returns: A boolean that indicates whether there is next page for the paginated items.
    @MainActor
    private func fetchItems(pageNumber: Int) async throws -> Bool {
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let newItems = pagedItems.items
        let uniqueNewItems = newItems.filter { newItem in
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)
        return pagedItems.hasMorePages
    }

    private func updateItemListStateAfterLoadAttempt() {
        if allItems.isEmpty {
            itemListStateSubject.send(.empty)
        } else {
            itemListStateSubject.send(.loaded(allItems))
        }
    }
}
