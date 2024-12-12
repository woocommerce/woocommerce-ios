import Foundation
import Combine
import enum Yosemite.POSItem
import struct Yosemite.POSParentProduct
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.PointOfSaleProductServiceError
import protocol Yosemite.PointOfSaleVariationServiceProtocol

protocol PointOfSaleItemsControllerProtocol {
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async
    func loadChildItems(for parentItem: POSParentProduct) async -> ItemListState
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    private(set) var itemsViewStatePublisher: any Publisher<ItemsViewState, Never>
    private var itemsViewStateSubject: PassthroughSubject<ItemsViewState, Never> = .init()
    private var allItems: [POSItem] = []
    private var itemsStackState: ItemsStackState
    private var currentPage: Int = Constants.initialPage
    private var mightHaveMorePages: Bool = true
    private let rootItemProvider: PointOfSaleItemServiceProtocol

    private var allChildItems: [UUID: [POSItem]] = [:]
    private let variationProvider: PointOfSaleVariationServiceProtocol

    init(rootItemProvider: PointOfSaleItemServiceProtocol,
         variationProvider: PointOfSaleVariationServiceProtocol) {
        self.rootItemProvider = rootItemProvider
        self.variationProvider = variationProvider
        itemsViewStatePublisher = itemsViewStateSubject.eraseToAnyPublisher()
        self.itemsStackState = .init(rootState: .loading([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true)), itemStates: [:])
    }

    @MainActor
    func loadInitialItems() async {
        mightHaveMorePages = true
        itemsViewStateSubject.send(ItemsViewState(containerState: .initialLoading, itemsStackState: .init(rootState: .loading([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true)), itemStates: [:])))
        do {
            try await load(pageNumber: Constants.initialPage)
        } catch {
            itemsViewStateSubject.send(ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                                      itemsStackState: itemsStackState))
        }
    }

    @MainActor
    func loadNextItems() async {
        do {
            guard mightHaveMorePages else {
                return
            }
            itemsViewStateSubject.send(ItemsViewState(containerState: .content, itemsStackState: itemsStackState))

            let nextPage = currentPage + 1
            try await load(pageNumber: nextPage)
            currentPage = nextPage
        } catch {
            // Handle errors without incrementing currentPage.
        }
    }

    @MainActor
    func reload() async {
        currentPage = Constants.initialPage
        mightHaveMorePages = true
        itemsStackState.rootState = .loading([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
        itemsViewStateSubject.send(ItemsViewState(containerState: .content, itemsStackState: itemsStackState))
        try? await load(pageNumber: currentPage)
    }

    @MainActor
    private func load(pageNumber: Int, parent: POSItem? = nil) async throws {
        do {
            if let parent {
                try await fetchItems(pageNumber: pageNumber, parent: parent)
            } else {
                try await fetchItems(pageNumber: pageNumber)
            }
            mightHaveMorePages = true
            updateItemViewStateAfterLoadAttempt()
        } catch PointOfSaleProductServiceError.pageOutOfRange {
            mightHaveMorePages = false
            updateItemViewStateAfterLoadAttempt()
            throw PointOfSaleProductServiceError.pageOutOfRange
        }
    }

    @MainActor
    private func fetchItems(pageNumber: Int, parent: POSItem) async throws {
        guard case .parentProduct(let parentProduct) = parent else {
            throw PointOfSaleItemsControllerError.cannotFetchChildrenForNonParentItem
        }
        let newItems = try await variationProvider.providePointOfSaleItems(for: parentProduct, pageNumber: pageNumber)
        let existingItems = itemsStackState.itemStates[parent]?.items ?? []

        let uniqueNewItems = newItems.filter { newItem in
            !existingItems.contains(newItem)
        }

        itemsStackState.itemStates[parent] = .loaded(existingItems + uniqueNewItems,
                                                     pageInfo: .init(currentPage: pageNumber, hasMorePages: true))
}

    @MainActor
    private func fetchItems(pageNumber: Int) async throws {
        let newItems = try await rootItemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let existingItems = itemsStackState.rootState.items

        let uniqueNewItems = newItems.filter { newItem in
            !existingItems.contains(newItem)
        }

        itemsStackState.rootState = .loaded(existingItems + uniqueNewItems,
                                            pageInfo: .init(currentPage: pageNumber, hasMorePages: true))
    }

    private func updateItemViewStateAfterLoadAttempt() {
        if itemsStackState.rootState.items.isEmpty {
            itemsViewStateSubject.send(.init(containerState: .empty, itemsStackState: itemsStackState))
        } else {
            itemsViewStateSubject.send(.init(containerState: .content, itemsStackState: itemsStackState))
        }
    }

    @MainActor
    func loadChildItems(for parentProduct: POSParentProduct) async -> ItemListState {
        do {
            let existingItems = allChildItems[parentProduct.id] ?? []
            if existingItems.isNotEmpty {
                return ItemListState.loaded(existingItems, pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
            }

            let newItems = try await variationProvider.providePointOfSaleItems(for: parentProduct, pageNumber: Constants.initialPage)
            let updatedItems = existingItems + newItems

            allChildItems[parentProduct.id] = updatedItems
            return ItemListState.loaded(updatedItems, pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
        } catch {
            DDLogError("Error loading child items for \(parentProduct): \(error)")
        }
        return ItemListState.loaded([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
    }

    private enum Constants {
        static let initialPage: Int = 1
    }
}

enum PointOfSaleItemsControllerError: Error {
    case cannotFetchChildrenForNonParentItem
}

extension ItemListState {
    var items: [POSItem] {
        switch self {
        case .loading(let items, _),
                .loaded(let items, _):
            return items
        }
    }
}
