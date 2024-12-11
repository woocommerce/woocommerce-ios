import SwiftUI
import Yosemite

// TODO: Maybe not a view helper because it's not stateless
// TODO: Try replacing this with another `PointOfSaleItemsController` for child items
final class PointOfSaleRootItemListViewHelper: ObservableObject {
    @Published var childItemListState: ItemListState = .empty
    private var allChildItems: [UUID: [POSItem]] = [:]
    private let variationProvider: PointOfSaleVariationServiceProtocol

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
}

private enum Constants {
    static let initialPage: Int = 1
}
