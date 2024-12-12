import Foundation
import Combine
import enum Yosemite.POSItem
import struct Yosemite.POSParentProduct
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.PointOfSaleProductServiceError
import protocol Yosemite.PointOfSaleVariationServiceProtocol

protocol PointOfSaleItemsControllerProtocol {
    var itemListStatePublisher: any Publisher<ItemListState, Never> { get }
    var itemListViewStatePublisher: any Publisher<ItemListViewState, Never> { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async
    func loadChildItems(for parentItem: POSParentProduct) async -> ItemListViewState
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    private(set) var itemListStatePublisher: any Publisher<ItemListState, Never>
    private var itemListStateSubject: PassthroughSubject<ItemListState, Never> = .init()
    private(set) var itemListViewStatePublisher: any Publisher<ItemListViewState, Never>
    private var itemListViewStateSubject: PassthroughSubject<ItemListViewState, Never> = .init()
    private var allItems: [POSItem] = []
    private var currentPage: Int = Constants.initialPage
    private var mightHaveMorePages: Bool = true
    private let rootItemProvider: PointOfSaleItemServiceProtocol

    private var allChildItems: [UUID: [POSItem]] = [:]
    private let variationProvider: PointOfSaleVariationServiceProtocol

    init(rootItemProvider: PointOfSaleItemServiceProtocol,
         variationProvider: PointOfSaleVariationServiceProtocol) {
        self.rootItemProvider = rootItemProvider
        self.variationProvider = variationProvider
        itemListStatePublisher = itemListStateSubject.eraseToAnyPublisher()
        itemListViewStatePublisher = itemListViewStateSubject.eraseToAnyPublisher()
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
            itemListViewStateSubject.send(.loading(allItems, pageInfo: PageInfo(currentPage: currentPage, hasMorePages: true)))

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
        itemListViewStateSubject.send(.loading(allItems, pageInfo: PageInfo(currentPage: currentPage, hasMorePages: true)))
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
        let newItems = try await rootItemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems.filter { newItem in
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)
    }

    private func updateItemListStateAfterLoadAttempt() {
        if allItems.isEmpty {
            itemListStateSubject.send(.empty)
        } else {
            itemListStateSubject.send(.itemsList)
            itemListViewStateSubject.send(.loaded(allItems, pageInfo: PageInfo(currentPage: currentPage, hasMorePages: true)))
        }
    }

    @MainActor
    func loadChildItems(for parentProduct: POSParentProduct) async -> ItemListViewState {
        do {
            let existingItems = allChildItems[parentProduct.id] ?? []
            if existingItems.isNotEmpty {
                return ItemListViewState.loaded(existingItems, pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
            }

            let newItems = try await variationProvider.providePointOfSaleItems(for: parentProduct, pageNumber: Constants.initialPage)
            let updatedItems = existingItems + newItems

            allChildItems[parentProduct.id] = updatedItems
            return ItemListViewState.loaded(updatedItems, pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
        } catch {
            DDLogError("Error loading child items for \(parentProduct): \(error)")
        }
        return ItemListViewState.loaded([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
    }

    private enum Constants {
        static let initialPage: Int = 1
    }
}
