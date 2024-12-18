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
    private var itemsViewState: ItemsViewState = .init(containerState: .loading, itemsStack: [:]) {
        didSet {
            itemsViewStateSubject.send(itemsViewState)
        }
    }
    private let paginationTracker: PaginationTracker = PaginationTracker()
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
        itemsViewStatePublisher = itemsViewStateSubject.eraseToAnyPublisher()

        paginationTracker.delegate = self
    }

    @MainActor
    func loadInitialItems() async {
        itemsViewState = ItemsViewState(containerState: .loading, itemsStack: [:])
        await withCheckedContinuation { continuation in
            paginationTracker.syncFirstPage {
                continuation.resume()
            }
        }
    }

    @MainActor
    func loadNextItems() async {
        let currentItems = itemsViewState.itemsStack[.root]?.items ?? []
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: [.root: .loading(currentItems)])
        await withCheckedContinuation { continuation in
            paginationTracker.ensureNextPageIsSynced {
                continuation.resume()
            }
        }
        let updatedItems = itemsViewState.itemsStack[.root]?.items ?? []
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: [.root: .loaded(updatedItems)])
    }

    @MainActor
    func reload() async {
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: [.root: .loading([])])
        await withCheckedContinuation { continuation in
            paginationTracker.resync {
                continuation.resume()
            }
        }
    }

    @MainActor
    private func fetchItems(pageNumber: Int) async throws -> Bool {
        let (newItems, hasNextPage) = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        var allItems = itemsViewState.itemsStack[.root]?.items ?? []
        let uniqueNewItems = newItems.filter { newItem in
            // Note that this uniquing won't currently work, as POSItem has a UUID.
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)
        itemsViewState = ItemsViewState(containerState: .content,
                                        itemsStack: [.root: .loaded(allItems)])
        return hasNextPage
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

extension PointOfSaleItemsController: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        Task { @MainActor in
            do {
                let hasNextPage = try await fetchItems(pageNumber: pageNumber)
                onCompletion?(.success(hasNextPage))
            } catch {
                itemsViewState = ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                                itemsStack: [:])
                onCompletion?(.failure(error))
            }
        }
    }
}
