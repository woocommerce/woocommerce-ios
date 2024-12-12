import Foundation
import Combine
import protocol Yosemite.POSDisplayableItem
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
    private var allItems: [POSDisplayableItem] = []
    private var currentPage: Int = Constants.initialPage
    private var mightHaveMorePages: Bool = true
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
        itemListStatePublisher = itemListStateSubject.eraseToAnyPublisher()
    }

    @MainActor
    func loadInitialItems() async {
        mightHaveMorePages = true
        itemListStateSubject.send(.initialLoading)
        try? await load(pageNumber: Constants.initialPage)
    }

    @MainActor
    func loadNextItems() async {
        do {
            guard mightHaveMorePages else {
                return
            }
            itemListStateSubject.send(.loading(allItems))

            let nextPage = currentPage + 1
            try await load(pageNumber: nextPage)
            currentPage = nextPage
        } catch {
            // Handle errors without incrementing currentPage.
        }
    }

    @MainActor
    func reload() async {
        allItems.removeAll()
        currentPage = Constants.initialPage
        mightHaveMorePages = true
        itemListStateSubject.send(.loading(allItems))
        try? await load(pageNumber: currentPage)
    }

    @MainActor
    private func load(pageNumber: Int) async throws {
        do {
            try await fetchItems(pageNumber: pageNumber)
            mightHaveMorePages = true
            updateItemListStateAfterLoadAttempt()
        } catch PointOfSaleProductServiceError.pageOutOfRange {
            mightHaveMorePages = false
            updateItemListStateAfterLoadAttempt()
            throw PointOfSaleProductServiceError.pageOutOfRange
        } catch {
            itemListStateSubject.send(.error(PointOfSaleErrorState.errorOnLoadingProducts()))
            throw error
        }
    }

    @MainActor
    private func fetchItems(pageNumber: Int) async throws {
        let newItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems.filter { newItem in
            !allItems.contains(where: { $0.isEqual(to: newItem) })
        }
        allItems.append(contentsOf: uniqueNewItems)
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
