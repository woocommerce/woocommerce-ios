import SwiftUI
import Yosemite

// TODO: Maybe not a view helper because it's not stateless
// TODO: Try replacing this with another `PointOfSaleItemsController` for child items
final class PointOfSaleRootItemListViewHelper: ObservableObject {
    @Published var childItemListState: ItemListState = .empty
    private var allChildItems: [UUID: [POSItem]] = [:]
    private let variationProvider: PointOfSaleVariationServiceProtocol
    private var currentPage: Int = Constants.initialPage
    private var mightHaveMorePages: Bool = true

    init(variationProvider: PointOfSaleVariationServiceProtocol) {
        self.variationProvider = variationProvider
    }

    @MainActor
    func loadChildItems(for parentProduct: POSParentProduct) async {
        do {
            let existingItems = allChildItems[parentProduct.id] ?? []
            childItemListState = .loading(existingItems, context: .child(parent: parentProduct, parentItem: .parentProduct(parentProduct)), pageInfo: PageInfo(currentPage: Constants.initialPage, hasMorePages: true))

            let newItems = try await variationProvider.providePointOfSaleItems(for: parentProduct, pageNumber: Constants.initialPage)
            let updatedItems = existingItems + newItems

            allChildItems[parentProduct.id] = updatedItems
            childItemListState = .loaded(updatedItems, context: .child(parent: parentProduct, parentItem: .parentProduct(parentProduct)), pageInfo: PageInfo(currentPage: Constants.initialPage, hasMorePages: true))
        } catch {
            DDLogError("Error loading child items for \(parentProduct): \(error)")
        }
    }

    @MainActor
    func loadNextChildItems() async {
        do {
            guard mightHaveMorePages else {
                return
            }
//            childItemListState = .loading(allItems, context: .root, pageInfo: PageInfo(currentPage: currentPage, hasMorePages: true))

            let nextPage = currentPage + 1
            try await load(pageNumber: nextPage)
            currentPage = nextPage
        } catch {
            // Handle errors without incrementing currentPage.
        }
    }

    @MainActor
    func reloadChildItems() async {
        allChildItems.removeAll()
        currentPage = Constants.initialPage
        mightHaveMorePages = true
//        childItemListState = .loading(allItems, context: .root, pageInfo: PageInfo(currentPage: currentPage, hasMorePages: true))
        try? await load(pageNumber: currentPage)
    }

    @MainActor
    private func load(pageNumber: Int) async throws {
//        do {
//            try await fetchItems(pageNumber: pageNumber)
//            mightHaveMorePages = true
//            updateItemListStateAfterLoadAttempt()
//        } catch PointOfSaleProductServiceError.pageOutOfRange {
//            mightHaveMorePages = false
//            updateItemListStateAfterLoadAttempt()
//            throw PointOfSaleProductServiceError.pageOutOfRange
//        } catch {
//            itemListStateSubject.send(.error(PointOfSaleErrorState.errorOnLoadingProducts()))
//            throw error
//        }
    }
}

private enum Constants {
    static let initialPage: Int = 1
}
