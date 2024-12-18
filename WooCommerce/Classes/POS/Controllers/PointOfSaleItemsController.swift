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
    private let paginationTracker: PaginationTracker
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
        self.paginationTracker = .init(pageFirstIndex: Constants.initialPage)
        itemListStatePublisher = itemListStateSubject.eraseToAnyPublisher()

        paginationTracker.delegate = self
    }

    @MainActor
    func loadInitialItems() async {
        itemListStateSubject.send(.initialLoading)
        paginationTracker.syncFirstPage()
    }

    @MainActor
    func loadNextItems() async {
        paginationTracker.ensureNextPageIsSynced()
    }

    @MainActor
    func reload() async {
        allItems.removeAll()
        itemListStateSubject.send(.loading(allItems))
        paginationTracker.resync()
    }

    @MainActor
    private func load(pageNumber: Int) async throws {
        do {
            try await fetchItems(pageNumber: pageNumber)
            updateItemListStateAfterLoadAttempt()
        } catch PointOfSaleProductServiceError.pageOutOfRange {
            updateItemListStateAfterLoadAttempt()
            throw PointOfSaleProductServiceError.pageOutOfRange
        } catch {
            itemListStateSubject.send(.error(PointOfSaleErrorState.errorOnLoadingProducts()))
            throw error
        }
    }
    
    /// <#Description#>
    /// - Parameter pageNumber: <#pageNumber description#>
    /// - Returns: A boolean that indicates whether there is next page for the paginated items.
    @MainActor
    private func fetchItems(pageNumber: Int) async throws -> Bool {
        let (newItems, hasNextPage) = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems.filter { newItem in
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)
        return hasNextPage
    }

    private func updateItemListStateAfterLoadAttempt() {
        if allItems.isEmpty {
            itemListStateSubject.send(.empty)
        } else {
            itemListStateSubject.send(.loaded(allItems))
        }
    }

    private enum Constants {
        static let initialPage: Int = 1
    }
}

extension PointOfSaleItemsController: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        itemListStateSubject.send(.loading(allItems))
        Task { @MainActor in
            do {
                let hasNextPage = try await fetchItems(pageNumber: pageNumber)
                updateItemListStateAfterLoadAttempt()
                onCompletion?(.success(hasNextPage))
            } catch PointOfSaleProductServiceError.pageOutOfRange {
                updateItemListStateAfterLoadAttempt()
                onCompletion?(.failure(PointOfSaleProductServiceError.pageOutOfRange))
            } catch {
                itemListStateSubject.send(.error(PointOfSaleErrorState.errorOnLoadingProducts()))
                onCompletion?(.failure(error))
            }
            itemListStateSubject.send(.loaded(allItems))
        }
    }
}
